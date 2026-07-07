import AVFoundation
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import Vision

private let maxCrossTrackIoU = 0.75

struct TrackBoxesSeed {
    let anchorFrameIndex: Int
    let timestamp: CMTime
    let method: String
    let boxes: [CGRect]
    let confidences: [Float]
}

struct TrackBoxesResult {
    let options: TrackBoxesOptions
    let metadata: VideoMetadata
    let outputSize: CGSize
    let seed: TrackBoxesSeed
    let tracks: [ObjectTrack]
    let timestamps: [CMTime]
}

func runTrackBoxes(_ options: TrackBoxesOptions) throws {
    try validateTrackBoxes(options)

    let reporter = ProgressReporter(json: options.progressJSON)
    reporter.log("Loading video metadata...")
    let metadata = try VideoMetadata.load(from: options.inputURL)
    let outputSize = TrackBoxSizing.outputSize(for: metadata.displaySize)
    reporter.progress(stage: "metadata", frame: 0, totalFrames: metadata.estimatedFrameCount)

    reporter.log("Finding initial people boxes...")
    let seed = try HumanBoxSeeder(
        options: options,
        metadata: metadata,
        outputSize: outputSize
    ).seed(reporter: reporter)
    reporter.log("Tracking anchor: frame \(seed.anchorFrameIndex), method \(seed.method)")

    let result = try VisionObjectBoxTracker(
        options: options,
        metadata: metadata,
        outputSize: outputSize,
        seed: seed
    ).track(reporter: reporter)

    if let debugJSONURL = options.debugJSONURL {
        reporter.log("Writing debug JSON...")
        try TrackBoxesDebugWriter.write(result: result, to: debugJSONURL)
    }

    reporter.log("Rendering tracked boxes...")
    try TrackBoxesVideoRenderer.render(result: result, reporter: reporter)
    reporter.done(totalFrames: max(result.timestamps.count, metadata.estimatedFrameCount))
    reporter.log("Wrote tracked boxes to \(options.outputURL.path)")
}

private func validateTrackBoxes(_ options: TrackBoxesOptions) throws {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: options.inputURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
        throw AppError.validation("Input video does not exist: \(options.inputURL.path)")
    }

    let allowedInputs = ["mp4", "mov", "m4v"]
    guard allowedInputs.contains(options.inputURL.pathExtension.lowercased()) else {
        throw AppError.validation("track-boxes input must be a local .mp4, .mov, or .m4v file: \(options.inputURL.path)")
    }

    let outputDirectory = options.outputURL.deletingLastPathComponent()
    guard fileManager.fileExists(atPath: outputDirectory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        throw AppError.validation("Output directory does not exist: \(outputDirectory.path)")
    }
    if fileManager.fileExists(atPath: options.outputURL.path), !options.overwrite {
        throw AppError.validation("Output already exists. Pass --overwrite to replace it: \(options.outputURL.path)")
    }
    if let debugURL = options.debugJSONURL,
       fileManager.fileExists(atPath: debugURL.path),
       !options.overwrite {
        throw AppError.validation("Debug JSON already exists. Pass --overwrite to replace it: \(debugURL.path)")
    }
}

private enum TrackBoxSizing {
    static func outputSize(for displaySize: CGSize) -> CGSize {
        CGSize(
            width: CGFloat(PixelBufferPool.even(Int(displaySize.width.rounded()))),
            height: CGFloat(PixelBufferPool.even(Int(displaySize.height.rounded())))
        )
    }
}

private final class HumanBoxSeeder {
    private let options: TrackBoxesOptions
    private let metadata: VideoMetadata
    private let outputSize: CGSize
    private let mapper: VisionCoordinateMapper

    init(options: TrackBoxesOptions, metadata: VideoMetadata, outputSize: CGSize) {
        self.options = options
        self.metadata = metadata
        self.outputSize = outputSize
        self.mapper = VisionCoordinateMapper(outputSize: outputSize)
    }

    func seed(reporter: ProgressReporter) throws -> TrackBoxesSeed {
        if let initialBoxes = options.initialBoxes {
            return try manualSeed(initialBoxes)
        }
        return try autoSeed(reporter: reporter)
    }

    private func manualSeed(_ boxes: [CGRect]) throws -> TrackBoxesSeed {
        let reader = try VideoReader(inputURL: options.inputURL, metadata: metadata)
        defer { reader.cancel() }
        guard let frame = try reader.nextFrame() else {
            throw AppError.videoIO("Input video contains no frames.")
        }

        let normalized = try boxes.enumerated().map { index, rect -> CGRect in
            let clamped = BoxGeometry.clampedToFrame(rect, frameSize: outputSize)
            guard BoxGeometry.isValidBox(clamped, frameSize: outputSize) else {
                throw AppError.invalidArguments("--initial-boxes entry \(index + 1) is outside the video frame or too small.")
            }
            return clamped
        }

        return TrackBoxesSeed(
            anchorFrameIndex: 0,
            timestamp: frame.presentationTime,
            method: "manual",
            boxes: normalized,
            confidences: Array(repeating: 1.0, count: normalized.count)
        )
    }

    private func autoSeed(reporter: ProgressReporter) throws -> TrackBoxesSeed {
        let reader = try VideoReader(inputURL: options.inputURL, metadata: metadata)
        defer { reader.cancel() }

        var bestPartial: (frameIndex: Int, count: Int)?
        while let frame = try reader.nextFrame() {
            if frame.index >= options.initScanFrames {
                break
            }

            let detections = try HumanDetector.detect(pixelBuffer: frame.pixelBuffer, mapper: mapper, frameSize: outputSize)
            if detections.count >= options.peopleCount {
                let selected = Array(detections.prefix(options.peopleCount)).sorted { $0.rect.minX < $1.rect.minX }
                return TrackBoxesSeed(
                    anchorFrameIndex: frame.index,
                    timestamp: frame.presentationTime,
                    method: "vision-auto",
                    boxes: selected.map(\.rect),
                    confidences: selected.map(\.confidence)
                )
            }

            if bestPartial == nil || detections.count > bestPartial!.count {
                bestPartial = (frame.index, detections.count)
            }
            if frame.index == 0 || frame.index.isMultiple(of: 30) {
                reporter.progress(stage: "box-init", frame: frame.index, totalFrames: max(metadata.estimatedFrameCount, options.initScanFrames))
            }
        }

        let detail: String
        if let bestPartial {
            detail = "Best scan frame \(bestPartial.frameIndex) had \(bestPartial.count) human rectangle(s)."
        } else {
            detail = "No frames were available to scan."
        }
        throw AppError.videoIO("Could not auto-detect \(options.peopleCount) people within the first \(options.initScanFrames) frames. \(detail) Use --initial-boxes to seed tracking manually.")
    }
}

private struct HumanDetection {
    let rect: CGRect
    let confidence: Float
}

private enum HumanDetector {
    static func detect(
        pixelBuffer: CVPixelBuffer,
        mapper: VisionCoordinateMapper,
        frameSize: CGSize
    ) throws -> [HumanDetection] {
        let request = VNDetectHumanRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try handler.perform([request])

        let detections = (request.results ?? []).compactMap { observation -> HumanDetection? in
            let detected = observation as VNDetectedObjectObservation
            let rect = BoxGeometry.clampedToFrame(mapper.pixelRect(fromVisionRect: detected.boundingBox), frameSize: frameSize)
            guard BoxGeometry.isValidBox(rect, frameSize: frameSize) else {
                return nil
            }
            return HumanDetection(rect: rect, confidence: detected.confidence)
        }

        return detections.sorted {
            if abs($0.confidence - $1.confidence) > 0.001 {
                return $0.confidence > $1.confidence
            }
            return $0.rect.height * $0.rect.width > $1.rect.height * $1.rect.width
        }
    }
}

private final class VisionObjectBoxTracker {
    private let options: TrackBoxesOptions
    private let metadata: VideoMetadata
    private let outputSize: CGSize
    private let seed: TrackBoxesSeed
    private let mapper: VisionCoordinateMapper

    init(options: TrackBoxesOptions, metadata: VideoMetadata, outputSize: CGSize, seed: TrackBoxesSeed) {
        self.options = options
        self.metadata = metadata
        self.outputSize = outputSize
        self.seed = seed
        self.mapper = VisionCoordinateMapper(outputSize: outputSize)
    }

    func track(reporter: ProgressReporter) throws -> TrackBoxesResult {
        let tracks = seed.boxes.enumerated().map { index, _ in
            ObjectTrack(trackID: index, color: TrackColor(rawValue: index) ?? .red)
        }
        var timestamps: [CMTime] = []
        var cachedPreAnchorFrames: [Int: CVPixelBuffer] = [:]

        for trackIndex in tracks.indices {
            try trackForwardPass(
                trackIndex: trackIndex,
                track: tracks[trackIndex],
                collectTimeline: trackIndex == 0,
                timestamps: &timestamps,
                cachedPreAnchorFrames: &cachedPreAnchorFrames,
                reporter: reporter
            )
        }

        guard !timestamps.isEmpty else {
            throw AppError.videoIO("Input video contains no frames.")
        }

        rejectRecordedCollisions(tracks: tracks, timestamps: timestamps)
        try runBackwardPass(frames: cachedPreAnchorFrames, tracks: tracks, timestamps: timestamps, reporter: reporter)

        for track in tracks {
            let corrected = BackwardCorrector.correctedTimeline(
                track: track,
                timestamps: timestamps,
                frameSize: outputSize,
                window: options.deadReckoningWindow,
                maxDeadReckonFrames: options.maxDeadReckonFrames
            )
            corrected.values.forEach { track.recordCorrected($0) }
        }

        return TrackBoxesResult(
            options: options,
            metadata: metadata,
            outputSize: outputSize,
            seed: seed,
            tracks: tracks,
            timestamps: timestamps
        )
    }

    private func trackForwardPass(
        trackIndex: Int,
        track: ObjectTrack,
        collectTimeline: Bool,
        timestamps: inout [CMTime],
        cachedPreAnchorFrames: inout [Int: CVPixelBuffer],
        reporter: ProgressReporter
    ) throws {
        let reader = try VideoReader(inputURL: options.inputURL, metadata: metadata)
        defer { reader.cancel() }

        let handler = VNSequenceRequestHandler()
        var request: VNTrackObjectRequest?
        var reachedAnchor = false

        while let frame = try reader.nextFrame() {
            if collectTimeline {
                timestamps.append(frame.presentationTime)
                if frame.index <= seed.anchorFrameIndex {
                    cachedPreAnchorFrames[frame.index] = try PixelBufferCopy.copy(frame.pixelBuffer)
                }
            }

            if frame.index < seed.anchorFrameIndex {
                continue
            }

            if frame.index == seed.anchorFrameIndex {
                let rect = seed.boxes[trackIndex]
                let observation = VNDetectedObjectObservation(boundingBox: mapper.visionRect(fromPixelRect: rect))
                let activeRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                activeRequest.trackingLevel = options.trackingLevel.visionLevel
                request = activeRequest
                reachedAnchor = true

                let box = TrackedBox(
                    frameIndex: frame.index,
                    timestamp: frame.presentationTime,
                    trackID: trackIndex,
                    color: track.color,
                    rect: rect,
                    confidence: seed.confidences[trackIndex],
                    source: .seed,
                    isVisible: true
                )
                track.recordForward(box, reliable: true)
                if collectTimeline {
                    reporter.progress(stage: "box-tracking", frame: frame.index, totalFrames: metadata.estimatedFrameCount)
                }
                continue
            }

            guard let request else {
                continue
            }

            try autoreleasepool {
                try trackSingleFrame(
                    frame: frame,
                    handler: handler,
                    request: request,
                    track: track
                )
            }

            if collectTimeline && (frame.index == 1 || frame.index.isMultiple(of: 30)) {
                reporter.progress(stage: "box-tracking", frame: frame.index, totalFrames: metadata.estimatedFrameCount)
            }
        }

        if !reachedAnchor {
            throw AppError.videoIO("Tracking never reached anchor frame \(seed.anchorFrameIndex).")
        }
    }

    private func trackSingleFrame(
        frame: VideoFrame,
        handler: VNSequenceRequestHandler,
        request: VNTrackObjectRequest,
        track: ObjectTrack
    ) throws {
        try handler.perform([request], on: frame.pixelBuffer)

        var candidate: TrackedBox?
        var candidateObservation: VNDetectedObjectObservation?
        if let observation = request.results?.first as? VNDetectedObjectObservation {
            let rawRect = BoxGeometry.clampedToFrame(mapper.pixelRect(fromVisionRect: observation.boundingBox), frameSize: outputSize)
            track.rawVisionForwardByFrame[frame.index] = rawRect

            if observation.confidence < options.trackerConfidenceThreshold {
                track.rejectedReasonByFrame[frame.index] = "low tracker confidence \(observation.confidence)"
            } else if !BoxGeometry.isValidBox(rawRect, frameSize: outputSize) {
                track.rejectedReasonByFrame[frame.index] = "invalid tracker box"
            } else {
                candidate = TrackedBox(
                    frameIndex: frame.index,
                    timestamp: frame.presentationTime,
                    trackID: track.trackID,
                    color: track.color,
                    rect: rawRect,
                    confidence: observation.confidence,
                    source: .visionForward,
                    isVisible: true
                )
                candidateObservation = observation
            }
        } else {
            track.rejectedReasonByFrame[frame.index] = "no Vision result"
        }

        if candidate == nil, shouldReacquire(frameIndex: frame.index, candidates: [:]) {
            candidate = try reacquireSingle(frame: frame, track: track)
        }

        if let candidate {
            track.recordForward(candidate, reliable: candidate.isReliableObservation)
            if let candidateObservation, candidate.source == .visionForward {
                request.inputObservation = candidateObservation
            } else {
                request.inputObservation = VNDetectedObjectObservation(boundingBox: mapper.visionRect(fromPixelRect: candidate.rect))
            }
        } else {
            let predicted = DeadReckoner.box(
                for: track,
                frameIndex: frame.index,
                timestamp: frame.presentationTime,
                frameSize: outputSize,
                maxDeadReckonFrames: options.maxDeadReckonFrames
            )
            track.recordForward(predicted, reliable: false)
            if predicted.isVisible {
                request.inputObservation = VNDetectedObjectObservation(boundingBox: mapper.visionRect(fromPixelRect: predicted.rect))
            }
        }
    }

    private func shouldReacquire(frameIndex: Int, candidates: [Int: TrackedBox]) -> Bool {
        guard options.reacquireEnabled,
              options.reacquireInterval > 0,
              frameIndex.isMultiple(of: options.reacquireInterval) else {
            return false
        }
        return candidates.count < options.peopleCount
    }

    private func reacquireSingle(frame: VideoFrame, track: ObjectTrack) throws -> TrackedBox? {
        let detections = try HumanDetector.detect(pixelBuffer: frame.pixelBuffer, mapper: mapper, frameSize: outputSize)
        guard !detections.isEmpty,
              let previous = track.lastReliableBox else {
            return nil
        }

        var best: (detection: HumanDetection, score: Double)?
        for detection in detections {
            let iou = BoxGeometry.boxIoU(previous.rect, detection.rect)
            let distance = BoxGeometry.centroidDistance(previous.rect, detection.rect, frameSize: outputSize)
            let size = BoxGeometry.sizeSimilarity(previous.rect, detection.rect)
            let score = iou * 0.65 + max(0, 1 - distance * 3.0) * 0.25 + size * 0.10
            if best == nil || score > best!.score {
                best = (detection, score)
            }
        }

        guard let best,
              best.score >= 0.18 else {
            return nil
        }

        track.reacquireCandidateByFrame[frame.index] = best.detection.rect
        return TrackedBox(
            frameIndex: frame.index,
            timestamp: frame.presentationTime,
            trackID: track.trackID,
            color: track.color,
            rect: best.detection.rect,
            confidence: best.detection.confidence,
            source: .reacquired,
            isVisible: true
        )
    }

    private func rejectRecordedCollisions(tracks: [ObjectTrack], timestamps: [CMTime]) {
        for frameIndex in timestamps.indices {
            var candidates: [TrackedBox] = tracks.compactMap { track in
                guard let box = track.forwardBoxes[frameIndex],
                      box.isVisible,
                      box.source != .seed,
                      box.source != .deadReckoned else {
                    return nil
                }
                return box
            }
            guard candidates.count > 1 else {
                continue
            }

            var rejected = Set<Int>()
            candidates.sort { $0.trackID < $1.trackID }
            for leftPosition in candidates.indices {
                for rightPosition in candidates.indices where rightPosition > leftPosition {
                    let left = candidates[leftPosition]
                    let right = candidates[rightPosition]
                    guard !rejected.contains(left.trackID),
                          !rejected.contains(right.trackID) else {
                        continue
                    }
                    let iou = BoxGeometry.boxIoU(left.rect, right.rect)
                    guard iou > maxCrossTrackIoU else {
                        continue
                    }

                    let rejectID: Int
                    if abs(left.confidence - right.confidence) > 0.05 {
                        rejectID = left.confidence < right.confidence ? left.trackID : right.trackID
                    } else {
                        rejectID = left.trackID > right.trackID ? left.trackID : right.trackID
                    }
                    let track = tracks[rejectID]
                    track.rejectedReasonByFrame[frameIndex] = "cross-track overlap \(String(format: "%.3f", iou))"
                    let missing = TrackedBox(
                        frameIndex: frameIndex,
                        timestamp: timestamps[frameIndex],
                        trackID: rejectID,
                        color: track.color,
                        rect: .null,
                        confidence: 0,
                        source: .missing,
                        isVisible: false
                    )
                    track.forwardBoxes[frameIndex] = missing
                    track.correctedBoxes[frameIndex] = missing
                    rejected.insert(rejectID)
                }
            }
        }
    }

    private func runBackwardPass(
        frames: [Int: CVPixelBuffer],
        tracks: [ObjectTrack],
        timestamps: [CMTime],
        reporter: ProgressReporter
    ) throws {
        guard seed.anchorFrameIndex > 0 else {
            return
        }

        reporter.log("Running backward correction pass to frame 0...")
        for trackIndex in tracks.indices {
            let observation = VNDetectedObjectObservation(boundingBox: mapper.visionRect(fromPixelRect: seed.boxes[trackIndex]))
            let request = VNTrackObjectRequest(detectedObjectObservation: observation)
            request.trackingLevel = options.trackingLevel.visionLevel
            let handler = VNSequenceRequestHandler()

            for frameIndex in stride(from: seed.anchorFrameIndex - 1, through: 0, by: -1) {
                guard let pixelBuffer = frames[frameIndex] else {
                    continue
                }
                try handler.perform([request], on: pixelBuffer)
                guard let observation = request.results?.first as? VNDetectedObjectObservation else {
                    continue
                }
                let rect = BoxGeometry.clampedToFrame(mapper.pixelRect(fromVisionRect: observation.boundingBox), frameSize: outputSize)
                tracks[trackIndex].rawVisionBackwardByFrame[frameIndex] = rect
                guard observation.confidence >= options.trackerConfidenceThreshold,
                      BoxGeometry.isValidBox(rect, frameSize: outputSize),
                      frameIndex < timestamps.count else {
                    tracks[trackIndex].rejectedReasonByFrame[frameIndex] = "invalid backward tracker box"
                    continue
                }
                let box = TrackedBox(
                    frameIndex: frameIndex,
                    timestamp: timestamps[frameIndex],
                    trackID: trackIndex,
                    color: tracks[trackIndex].color,
                    rect: rect,
                    confidence: observation.confidence,
                    source: .visionBackward,
                    isVisible: true
                )
                tracks[trackIndex].recordBackward(box)
                request.inputObservation = observation

                if trackIndex == 0, frameIndex == 0 || frameIndex.isMultiple(of: 30) {
                    reporter.progress(stage: "box-backward", frame: seed.anchorFrameIndex - frameIndex, totalFrames: seed.anchorFrameIndex)
                }
            }
        }
    }
}

private enum PixelBufferCopy {
    static func copy(_ source: CVPixelBuffer) throws -> CVPixelBuffer {
        let width = CVPixelBufferGetWidth(source)
        let height = CVPixelBufferGetHeight(source)
        let pixelFormat = CVPixelBufferGetPixelFormatType(source)
        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: pixelFormat,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]

        var destination: CVPixelBuffer?
        let createStatus = CVPixelBufferCreate(nil, width, height, pixelFormat, attributes as CFDictionary, &destination)
        guard createStatus == kCVReturnSuccess, let destination else {
            throw AppError.videoIO("Could not copy frame buffer (status \(createStatus)).")
        }

        CVPixelBufferLockBaseAddress(source, .readOnly)
        CVPixelBufferLockBaseAddress(destination, [])
        defer {
            CVPixelBufferUnlockBaseAddress(destination, [])
            CVPixelBufferUnlockBaseAddress(source, .readOnly)
        }

        guard let sourceBase = CVPixelBufferGetBaseAddress(source),
              let destinationBase = CVPixelBufferGetBaseAddress(destination) else {
            throw AppError.videoIO("Could not access frame buffer memory.")
        }

        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(source)
        let destinationBytesPerRow = CVPixelBufferGetBytesPerRow(destination)
        let rowBytes = min(sourceBytesPerRow, destinationBytesPerRow)
        for row in 0..<height {
            let sourceRow = sourceBase.advanced(by: row * sourceBytesPerRow)
            let destinationRow = destinationBase.advanced(by: row * destinationBytesPerRow)
            memcpy(destinationRow, sourceRow, rowBytes)
        }
        return destination
    }
}

private enum TrackBoxesVideoRenderer {
    static func render(result: TrackBoxesResult, reporter: ProgressReporter) throws {
        let options = result.options
        let outputPool = try PixelBufferPool(
            width: Int(result.outputSize.width.rounded()),
            height: Int(result.outputSize.height.rounded())
        )
        let renderer = TrackBoxRenderer(outputSize: result.outputSize)
        let writer = try VideoWriter(
            outputURL: options.outputURL,
            outputSize: result.outputSize,
            bitrate: options.bitrate,
            overwrite: options.overwrite,
            inputURL: options.inputURL,
            includeAudio: false,
            duration: result.metadata.duration
        )
        let reader = try VideoReader(inputURL: options.inputURL, metadata: result.metadata)
        defer { reader.cancel() }

        var renderedFrames = 0
        while let frame = try reader.nextFrame() {
            try autoreleasepool {
                let output = try outputPool.makePixelBuffer()
                let boxes = result.tracks.compactMap { $0.correctedBoxes[frame.index] }
                try renderer.render(
                    source: frame.pixelBuffer,
                    boxes: boxes,
                    drawLabels: options.drawLabels,
                    debug: options.debug,
                    to: output
                )
                try writer.append(pixelBuffer: output, presentationTime: frame.presentationTime)
            }
            renderedFrames += 1
            if renderedFrames == 1 || renderedFrames.isMultiple(of: 30) {
                reporter.progress(stage: "box-render", frame: renderedFrames, totalFrames: result.metadata.estimatedFrameCount)
            }
        }

        try writer.finish()
    }
}

private enum TrackBoxesDebugWriter {
    static func write(result: TrackBoxesResult, to url: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            if result.options.overwrite {
                try fileManager.removeItem(at: url)
            } else {
                throw AppError.validation("Debug JSON already exists. Pass --overwrite to replace it: \(url.path)")
            }
        }

        let object: [String: Any] = [
            "options": optionsDictionary(result.options),
            "video": videoDictionary(result),
            "anchor": [
                "frameIndex": result.seed.anchorFrameIndex,
                "timestampSeconds": seconds(result.seed.timestamp),
                "method": result.seed.method
            ],
            "initialBoxes": result.seed.boxes.enumerated().map { index, rect in
                [
                    "trackID": index,
                    "color": TrackColor(rawValue: index)?.name ?? "unknown",
                    "confidence": result.seed.confidences[index],
                    "rect": rectDictionary(rect)
                ] as [String: Any]
            },
            "tracks": result.tracks.map { track in
                [
                    "trackID": track.trackID,
                    "color": track.color.name
                ] as [String: Any]
            },
            "frames": frameDictionaries(result)
        ]

        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: [.atomic])
    }

    private static func optionsDictionary(_ options: TrackBoxesOptions) -> [String: Any] {
        [
            "inputPath": options.inputURL.path,
            "outputPath": options.outputURL.path,
            "peopleCount": options.peopleCount,
            "initScanFrames": options.initScanFrames,
            "deadReckoningWindow": options.deadReckoningWindow,
            "maxDeadReckonFrames": options.maxDeadReckonFrames,
            "trackingLevel": options.trackingLevel.rawValue,
            "trackerConfidenceThreshold": options.trackerConfidenceThreshold,
            "reacquireEnabled": options.reacquireEnabled,
            "reacquireInterval": options.reacquireInterval,
            "drawLabels": options.drawLabels,
            "debug": options.debug,
            "bitrate": options.bitrate,
            "overwrite": options.overwrite,
            "progressJSON": options.progressJSON,
            "maxCrossTrackIoU": maxCrossTrackIoU
        ]
    }

    private static func videoDictionary(_ result: TrackBoxesResult) -> [String: Any] {
        var dictionary = result.metadata.dictionary
        dictionary["actualFrameCount"] = result.timestamps.count
        dictionary["outputWidth"] = Int(result.outputSize.width.rounded())
        dictionary["outputHeight"] = Int(result.outputSize.height.rounded())
        return dictionary
    }

    private static func frameDictionaries(_ result: TrackBoxesResult) -> [[String: Any]] {
        result.timestamps.indices.map { frameIndex in
            [
                "frameIndex": frameIndex,
                "timestampSeconds": seconds(result.timestamps[frameIndex]),
                "tracks": result.tracks.map { trackDictionary($0, frameIndex: frameIndex) }
            ] as [String: Any]
        }
    }

    private static func trackDictionary(_ track: ObjectTrack, frameIndex: Int) -> [String: Any] {
        let box = track.correctedBoxes[frameIndex]
        return [
            "trackID": track.trackID,
            "color": track.color.name,
            "rect": optionalRectDictionary(box?.rect),
            "confidence": box?.confidence ?? 0,
            "source": box?.source.rawValue ?? BoxSource.missing.rawValue,
            "isVisible": box?.isVisible ?? false,
            "velocity": vectorDictionary(track.velocityByFrame[frameIndex] ?? .zero),
            "missingFrameCount": track.missingCountByFrame[frameIndex] ?? 0,
            "rawVisionForward": optionalRectDictionary(track.rawVisionForwardByFrame[frameIndex]),
            "rawVisionBackward": optionalRectDictionary(track.rawVisionBackwardByFrame[frameIndex]),
            "reacquireCandidate": optionalRectDictionary(track.reacquireCandidateByFrame[frameIndex]),
            "rejectedReason": track.rejectedReasonByFrame[frameIndex] ?? NSNull()
        ]
    }

    private static func rectDictionary(_ rect: CGRect) -> [String: Any] {
        [
            "x": Double(rect.origin.x),
            "y": Double(rect.origin.y),
            "width": Double(rect.width),
            "height": Double(rect.height)
        ]
    }

    private static func optionalRectDictionary(_ rect: CGRect?) -> Any {
        guard let rect, rect.isFiniteRect, !rect.isNull else {
            return NSNull()
        }
        return rectDictionary(rect)
    }

    private static func vectorDictionary(_ vector: CGVector) -> [String: Any] {
        [
            "dx": Double(vector.dx),
            "dy": Double(vector.dy)
        ]
    }

    private static func seconds(_ time: CMTime) -> Double {
        time.seconds.isFinite ? time.seconds : 0
    }
}

private extension BoxTrackingLevel {
    var visionLevel: VNRequestTrackingLevel {
        switch self {
        case .fast:
            return .fast
        case .accurate:
            return .accurate
        }
    }
}
