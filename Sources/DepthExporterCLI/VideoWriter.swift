import AVFoundation
import CoreVideo
import Foundation

final class VideoWriter {
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private var audioReader: AVAssetReader?
    private var audioOutput: AVAssetReaderOutput?
    private var audioInput: AVAssetWriterInput?
    private let audioQueue = DispatchQueue(label: "depth-exporter.audio")
    private let audioFinished = DispatchSemaphore(value: 0)
    private var audioStarted = false
    private var audioEnabled = false
    private var audioError: String?
    private var didStartSession = false
    private var appendedFrames = 0
    let audioMessage: String?

    init(
        outputURL: URL,
        outputSize: CGSize,
        bitrate: Int,
        overwrite: Bool,
        inputURL: URL,
        includeAudio: Bool,
        duration: CMTime
    ) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            guard overwrite else {
                throw AppError.validation("Output already exists. Pass --overwrite to replace it: \(outputURL.path)")
            }
            try fileManager.removeItem(at: outputURL)
        }

        let directory = outputURL.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw AppError.validation("Output directory does not exist: \(directory.path)")
        }

        writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let width = PixelBufferPool.even(Int(outputSize.width.rounded()))
        let height = PixelBufferPool.even(Int(outputSize.height.rounded()))
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let sourceAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourceAttributes
        )

        guard writer.canAdd(input) else {
            throw AppError.videoIO("Could not add video writer input.")
        }
        writer.add(input)

        if includeAudio {
            audioMessage = try Self.configureAudio(
                writer: writer,
                inputURL: inputURL,
                duration: duration,
                audioReader: &audioReader,
                audioOutput: &audioOutput,
                audioInput: &audioInput,
                audioEnabled: &audioEnabled
            )
        } else {
            audioMessage = nil
        }

        guard writer.startWriting() else {
            throw AppError.videoIO("Could not start video writer: \(writer.error?.localizedDescription ?? "unknown error")")
        }
    }

    func append(pixelBuffer: CVPixelBuffer, presentationTime: CMTime) throws {
        if !didStartSession {
            writer.startSession(atSourceTime: presentationTime)
            didStartSession = true
            startAudioIfNeeded()
        }

        while !input.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.002)
            if writer.status == .failed {
                throw AppError.videoIO("Video writer failed: \(writer.error?.localizedDescription ?? "unknown error")")
            }
        }

        guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
            throw AppError.videoIO("Could not append frame at \(presentationTime.seconds)s: \(writer.error?.localizedDescription ?? "unknown error")")
        }
        appendedFrames += 1
    }

    func finish() throws {
        guard appendedFrames > 0 else {
            input.markAsFinished()
            writer.cancelWriting()
            throw AppError.videoIO("No frames were written.")
        }

        input.markAsFinished()
        if audioEnabled {
            audioFinished.wait()
            if let audioError {
                writer.cancelWriting()
                throw AppError.videoIO(audioError)
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        if writer.status == .failed {
            throw AppError.videoIO("Video writer failed: \(writer.error?.localizedDescription ?? "unknown error")")
        }
    }

    private func startAudioIfNeeded() {
        guard audioEnabled, !audioStarted, let audioReader, let audioOutput, let audioInput else {
            return
        }
        audioStarted = true
        guard audioReader.startReading() else {
            audioError = "Could not start audio reader: \(audioReader.error?.localizedDescription ?? "unknown error")"
            audioInput.markAsFinished()
            audioFinished.signal()
            return
        }

        audioInput.requestMediaDataWhenReady(on: audioQueue) { [weak self] in
            guard let self else {
                return
            }
            while audioInput.isReadyForMoreMediaData {
                if let sample = audioOutput.copyNextSampleBuffer() {
                    if !audioInput.append(sample) {
                        self.audioError = "Could not append audio sample: \(self.writer.error?.localizedDescription ?? "unknown error")"
                        audioInput.markAsFinished()
                        self.audioFinished.signal()
                        return
                    }
                } else {
                    if audioReader.status == .failed {
                        self.audioError = "Audio reader failed: \(audioReader.error?.localizedDescription ?? "unknown error")"
                    }
                    audioInput.markAsFinished()
                    self.audioFinished.signal()
                    return
                }
            }
        }
    }

    private static func configureAudio(
        writer: AVAssetWriter,
        inputURL: URL,
        duration: CMTime,
        audioReader: inout AVAssetReader?,
        audioOutput: inout AVAssetReaderOutput?,
        audioInput: inout AVAssetWriterInput?,
        audioEnabled: inout Bool
    ) throws -> String {
        let asset = AVURLAsset(url: inputURL)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            audioEnabled = false
            return "warning: --include-audio was set, but the input has no audio track. Exporting silent video."
        }

        do {
            try configurePassthroughAudio(
                writer: writer,
                asset: asset,
                track: track,
                duration: duration,
                audioReader: &audioReader,
                audioOutput: &audioOutput,
                audioInput: &audioInput,
                audioEnabled: &audioEnabled
            )
            return "Audio: including first source audio track (passthrough)."
        } catch {
            try configureAACAudio(
                writer: writer,
                asset: asset,
                track: track,
                duration: duration,
                audioReader: &audioReader,
                audioOutput: &audioOutput,
                audioInput: &audioInput,
                audioEnabled: &audioEnabled
            )
            return "Audio: including first source audio track (AAC re-encode)."
        }
    }

    private static func configurePassthroughAudio(
        writer: AVAssetWriter,
        asset: AVAsset,
        track: AVAssetTrack,
        duration: CMTime,
        audioReader: inout AVAssetReader?,
        audioOutput: inout AVAssetReaderOutput?,
        audioInput: inout AVAssetWriterInput?,
        audioEnabled: inout Bool
    ) throws {
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw AppError.videoIO("Could not add passthrough audio reader output.")
        }
        reader.add(output)
        reader.timeRange = CMTimeRange(start: .zero, duration: duration)

        let formatDescription = track.formatDescriptions.first as! CMFormatDescription?
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: nil, sourceFormatHint: formatDescription)
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else {
            throw AppError.videoIO("Could not add passthrough audio writer input.")
        }
        writer.add(input)
        audioReader = reader
        audioOutput = output
        audioInput = input
        audioEnabled = true
    }

    private static func configureAACAudio(
        writer: AVAssetWriter,
        asset: AVAsset,
        track: AVAssetTrack,
        duration: CMTime,
        audioReader: inout AVAssetReader?,
        audioOutput: inout AVAssetReaderOutput?,
        audioInput: inout AVAssetWriterInput?,
        audioEnabled: inout Bool
    ) throws {
        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw AppError.videoIO("Could not add AAC fallback audio reader output.")
        }
        reader.add(output)
        reader.timeRange = CMTimeRange(start: .zero, duration: duration)

        let audioSettings = aacSettings(for: track)
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else {
            throw AppError.videoIO("Could not add AAC fallback audio writer input.")
        }
        writer.add(input)
        audioReader = reader
        audioOutput = output
        audioInput = input
        audioEnabled = true
    }

    private static func aacSettings(for track: AVAssetTrack) -> [String: Any] {
        var sampleRate = 44_100.0
        var channels = 2

        if let description = track.formatDescriptions.first as! CMAudioFormatDescription?,
           let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee {
            if asbd.mSampleRate > 0 {
                sampleRate = asbd.mSampleRate
            }
            if asbd.mChannelsPerFrame > 0 {
                channels = Int(asbd.mChannelsPerFrame)
            }
        }

        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderBitRateKey: 128_000
        ]
    }
}
