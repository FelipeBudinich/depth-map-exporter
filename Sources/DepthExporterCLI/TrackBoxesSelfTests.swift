import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

enum TrackBoxesSelfTests {
    static func run() throws {
        try testTrackBoxesParser()
        try testDepthParserStillWorks()
        try testCoordinateMapping()
        try testDeadReckoning()
        try testBackwardCorrection()
        try testRendererDrawsBox()
        FileHandle.standardError.write(Data("track-boxes self-test: ok\n".utf8))
    }

    private static func testTrackBoxesParser() throws {
        let parsed = try Arguments.parse([
            "depth-exporter",
            "track-boxes",
            "input.mp4",
            "--output",
            "tracked.mp4",
            "--people-count",
            "2",
            "--initial-boxes",
            "10,20,30,40;50,60,70,80",
            "--dead-reckoning-window",
            "12",
            "--draw-labels",
            "false"
        ])

        guard case .trackBoxes(let options) = parsed else {
            throw AppError.internalFailure("Parser did not return track-boxes options.")
        }
        try assert(options.peopleCount == 2, "people count")
        try assert(options.initialBoxes?.count == 2, "initial boxes count")
        try assert(options.deadReckoningWindow == 12, "dead-reckoning window")
        try assert(options.drawLabels == false, "draw labels")
    }

    private static func testDepthParserStillWorks() throws {
        let parsed = try Arguments.parse([
            "depth-exporter",
            "--input",
            "input.mp4",
            "--output",
            "depth.mp4",
            "--model",
            "DepthAnythingV2SmallF16.mlpackage"
        ])

        guard case .run(let config) = parsed else {
            throw AppError.internalFailure("Parser did not return depth export config.")
        }
        try assert(config.normalize == .global, "depth parser normalize default")
        try assert(config.modelShortSide == 518, "depth parser model short side default")
    }

    private static func testCoordinateMapping() throws {
        let mapper = VisionCoordinateMapper(outputSize: CGSize(width: 1920, height: 1080))
        let rect = CGRect(x: 120, y: 80, width: 260, height: 720)
        let roundTrip = mapper.pixelRect(fromVisionRect: mapper.visionRect(fromPixelRect: rect))
        try assert(abs(roundTrip.minX - rect.minX) < 0.001, "mapping x")
        try assert(abs(roundTrip.minY - rect.minY) < 0.001, "mapping y")
        try assert(abs(roundTrip.width - rect.width) < 0.001, "mapping width")
        try assert(abs(roundTrip.height - rect.height) < 0.001, "mapping height")
    }

    private static func testDeadReckoning() throws {
        let track = ObjectTrack(trackID: 0, color: .red)
        let first = TrackedBox(
            frameIndex: 0,
            timestamp: .zero,
            trackID: 0,
            color: .red,
            rect: CGRect(x: 10, y: 10, width: 20, height: 30),
            confidence: 1,
            source: .seed,
            isVisible: true
        )
        let second = TrackedBox(
            frameIndex: 1,
            timestamp: CMTime(value: 1, timescale: 30),
            trackID: 0,
            color: .red,
            rect: CGRect(x: 14, y: 16, width: 20, height: 30),
            confidence: 1,
            source: .visionForward,
            isVisible: true
        )
        track.recordForward(first, reliable: true)
        track.recordForward(second, reliable: true)
        let predicted = DeadReckoner.box(
            for: track,
            frameIndex: 2,
            timestamp: CMTime(value: 2, timescale: 30),
            frameSize: CGSize(width: 100, height: 100),
            maxDeadReckonFrames: 10
        )
        try assert(predicted.isVisible, "dead reckoned visible")
        try assert(abs(predicted.rect.minX - 17.8) < 0.001, "dead reckoned x")
        try assert(abs(predicted.rect.minY - 21.7) < 0.001, "dead reckoned y")
    }

    private static func testBackwardCorrection() throws {
        let track = ObjectTrack(trackID: 0, color: .red)
        let timestamps = (0..<5).map { CMTime(value: CMTimeValue($0), timescale: 30) }
        let start = TrackedBox(
            frameIndex: 0,
            timestamp: timestamps[0],
            trackID: 0,
            color: .red,
            rect: CGRect(x: 0, y: 0, width: 10, height: 10),
            confidence: 1,
            source: .seed,
            isVisible: true
        )
        let end = TrackedBox(
            frameIndex: 4,
            timestamp: timestamps[4],
            trackID: 0,
            color: .red,
            rect: CGRect(x: 40, y: 20, width: 10, height: 10),
            confidence: 1,
            source: .visionBackward,
            isVisible: true
        )
        track.recordForward(start, reliable: true)
        track.recordBackward(end)
        let corrected = BackwardCorrector.correctedTimeline(
            track: track,
            timestamps: timestamps,
            frameSize: CGSize(width: 100, height: 100),
            window: 10,
            maxDeadReckonFrames: 10
        )
        guard let middle = corrected[2] else {
            throw AppError.internalFailure("Missing corrected middle frame.")
        }
        try assert(middle.source == .corrected, "corrected source")
        try assert(abs(middle.rect.minX - 20) < 0.001, "corrected interpolation x")
        try assert(abs(middle.rect.minY - 10) < 0.001, "corrected interpolation y")
    }

    private static func testRendererDrawsBox() throws {
        let pool = try PixelBufferPool(width: 64, height: 64)
        let source = try pool.makePixelBuffer()
        let output = try pool.makePixelBuffer()
        fill(source, gray: 20)

        let renderer = TrackBoxRenderer(outputSize: CGSize(width: 64, height: 64))
        let box = TrackedBox(
            frameIndex: 0,
            timestamp: .zero,
            trackID: 0,
            color: .red,
            rect: CGRect(x: 12, y: 12, width: 30, height: 30),
            confidence: 1,
            source: .seed,
            isVisible: true
        )
        try renderer.render(source: source, boxes: [box], drawLabels: false, debug: false, to: output)
        try assert(hasRedPixel(output), "renderer red pixel")
    }

    private static func fill(_ pixelBuffer: CVPixelBuffer, gray: UInt8) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        for y in 0..<height {
            let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width {
                let offset = x * 4
                row[offset] = gray
                row[offset + 1] = gray
                row[offset + 2] = gray
                row[offset + 3] = 255
            }
        }
    }

    private static func hasRedPixel(_ pixelBuffer: CVPixelBuffer) -> Bool {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return false
        }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        for y in 0..<height {
            let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width {
                let offset = x * 4
                let blue = row[offset]
                let green = row[offset + 1]
                let red = row[offset + 2]
                if red > 180 && green < 80 && blue < 80 {
                    return true
                }
            }
        }
        return false
    }

    private static func assert(_ condition: Bool, _ label: String) throws {
        if !condition {
            throw AppError.internalFailure("Self-test failed: \(label).")
        }
    }
}
