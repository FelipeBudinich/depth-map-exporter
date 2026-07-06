import CoreGraphics
import CoreVideo
import Foundation

final class PixelBufferPool {
    let width: Int
    let height: Int
    let pixelFormat: OSType
    private let pool: CVPixelBufferPool

    init(width: Int, height: Int, pixelFormat: OSType = kCVPixelFormatType_32BGRA) throws {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat

        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: pixelFormat,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var created: CVPixelBufferPool?
        let status = CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary, &created)
        guard status == kCVReturnSuccess, let created else {
            throw AppError.videoIO("Could not create pixel buffer pool \(width)x\(height) (status \(status)).")
        }
        pool = created
    }

    func makePixelBuffer() throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        guard status == kCVReturnSuccess, let buffer else {
            throw AppError.videoIO("Could not allocate pixel buffer \(width)x\(height) (status \(status)).")
        }
        return buffer
    }

    static func nearestMultiple(of multiple: Int, to value: Int) -> Int {
        guard multiple > 0 else {
            return value
        }
        let rounded = Int((Double(value) / Double(multiple)).rounded()) * multiple
        return max(multiple, rounded)
    }

    static func even(_ value: Int) -> Int {
        let clamped = max(2, value)
        return clamped.isMultiple(of: 2) ? clamped : clamped - 1
    }

    static func modelInputSize(for displaySize: CGSize, shortSide: Int, multiple: Int = 14) -> CGSize {
        let roundedShort = nearestMultiple(of: multiple, to: shortSide)
        let width = max(1.0, Double(displaySize.width))
        let height = max(1.0, Double(displaySize.height))

        if width >= height {
            let long = nearestMultiple(of: multiple, to: Int((Double(roundedShort) * width / height).rounded()))
            return CGSize(width: long, height: roundedShort)
        } else {
            let long = nearestMultiple(of: multiple, to: Int((Double(roundedShort) * height / width).rounded()))
            return CGSize(width: roundedShort, height: long)
        }
    }

    static func outputSize(for displaySize: CGSize, maxSide: Int) -> CGSize {
        let sourceWidth = max(2.0, Double(displaySize.width.rounded()))
        let sourceHeight = max(2.0, Double(displaySize.height.rounded()))
        let longest = max(sourceWidth, sourceHeight)
        let scale = min(1.0, Double(maxSide) / longest)
        let width = even(Int((sourceWidth * scale).rounded()))
        let height = even(Int((sourceHeight * scale).rounded()))
        return CGSize(width: width, height: height)
    }
}
