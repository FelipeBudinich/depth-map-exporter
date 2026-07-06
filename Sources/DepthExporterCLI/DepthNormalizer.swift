import CoreML
import CoreVideo
import Foundation

struct DepthGrid {
    let width: Int
    let height: Int
    let values: [Float]

    init(output: DepthOutput) throws {
        switch output {
        case .pixelBuffer(let pixelBuffer):
            self = try Self(pixelBuffer: pixelBuffer)
        case .multiArray(let multiArray):
            self = try Self(multiArray: multiArray)
        }
    }

    private init(pixelBuffer: CVPixelBuffer) throws {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        var values = Array(repeating: Float.nan, count: width * height)

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw AppError.coreML("Depth image output has no base address.")
        }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        switch format {
        case kCVPixelFormatType_OneComponent8:
            for y in 0..<height {
                let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
                for x in 0..<width {
                    values[y * width + x] = Float(row[x]) / 255.0
                }
            }
        case kCVPixelFormatType_OneComponent16Half, kCVPixelFormatType_DisparityFloat16, kCVPixelFormatType_DepthFloat16:
            for y in 0..<height {
                let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt16.self)
                for x in 0..<width {
                    values[y * width + x] = Float(Float16(bitPattern: row[x]))
                }
            }
        case kCVPixelFormatType_OneComponent32Float, kCVPixelFormatType_DisparityFloat32, kCVPixelFormatType_DepthFloat32:
            for y in 0..<height {
                let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: Float.self)
                for x in 0..<width {
                    values[y * width + x] = row[x]
                }
            }
        case kCVPixelFormatType_32BGRA:
            for y in 0..<height {
                let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
                for x in 0..<width {
                    let offset = x * 4
                    let b = Float(row[offset])
                    let g = Float(row[offset + 1])
                    let r = Float(row[offset + 2])
                    values[y * width + x] = (0.0722 * b + 0.7152 * g + 0.2126 * r) / 255.0
                }
            }
        default:
            throw AppError.coreML("Unsupported depth image pixel format: \(format).")
        }

        self.width = width
        self.height = height
        self.values = values
    }

    private init(multiArray: MLMultiArray) throws {
        guard multiArray.shape.count >= 2 else {
            throw AppError.coreML("Depth MLMultiArray output must have at least two dimensions.")
        }

        let shape = multiArray.shape.map { $0.intValue }
        let strides = multiArray.strides.map { $0.intValue }
        let heightDimension = shape.count - 2
        let widthDimension = shape.count - 1
        let height = shape[heightDimension]
        let width = shape[widthDimension]
        guard width > 0, height > 0 else {
            throw AppError.coreML("Depth MLMultiArray output has invalid dimensions \(shape).")
        }

        var values = Array(repeating: Float.nan, count: width * height)
        let base = multiArray.dataPointer

        func elementOffset(x: Int, y: Int) -> Int {
            var offset = 0
            for dimension in 0..<shape.count {
                if dimension == heightDimension {
                    offset += y * strides[dimension]
                } else if dimension == widthDimension {
                    offset += x * strides[dimension]
                }
            }
            return offset
        }

        switch multiArray.dataType {
        case .float32:
            let pointer = base.assumingMemoryBound(to: Float.self)
            for y in 0..<height {
                for x in 0..<width {
                    values[y * width + x] = pointer[elementOffset(x: x, y: y)]
                }
            }
        case .double:
            let pointer = base.assumingMemoryBound(to: Double.self)
            for y in 0..<height {
                for x in 0..<width {
                    values[y * width + x] = Float(pointer[elementOffset(x: x, y: y)])
                }
            }
        case .float16:
            let pointer = base.assumingMemoryBound(to: UInt16.self)
            for y in 0..<height {
                for x in 0..<width {
                    values[y * width + x] = Float(Float16(bitPattern: pointer[elementOffset(x: x, y: y)]))
                }
            }
        case .int32:
            let pointer = base.assumingMemoryBound(to: Int32.self)
            for y in 0..<height {
                for x in 0..<width {
                    values[y * width + x] = Float(pointer[elementOffset(x: x, y: y)])
                }
            }
        case .int8:
            let pointer = base.assumingMemoryBound(to: Int8.self)
            for y in 0..<height {
                for x in 0..<width {
                    values[y * width + x] = Float(pointer[elementOffset(x: x, y: y)])
                }
            }
        @unknown default:
            throw AppError.coreML("Unsupported MLMultiArray data type: \(multiArray.dataType.rawValue).")
        }

        self.width = width
        self.height = height
        self.values = values
    }
}

struct DepthRange {
    let near: Float
    let far: Float

    var isUsable: Bool {
        near.isFinite && far.isFinite && far > near && (far - near) > 0.000001
    }

    static let fallback = DepthRange(near: 0, far: 1)
}

final class DepthNormalizer {
    private var stableRange: DepthRange?

    func range(for grid: DepthGrid, mode: NormalizationMode) -> DepthRange {
        let local = Self.percentileRange(for: grid)
        switch mode {
        case .global, .perFrame:
            return local
        case .ema:
            guard let previous = stableRange, previous.isUsable else {
                stableRange = local
                return local
            }
            let smoothed = DepthRange(
                near: lerp(previous.near, local.near, 0.05),
                far: lerp(previous.far, local.far, 0.05)
            )
            stableRange = smoothed.isUsable ? smoothed : local
            return stableRange ?? DepthRange.fallback
        }
    }

    static func percentileRange(for grid: DepthGrid) -> DepthRange {
        var valid = grid.values.filter { $0.isFinite }
        guard valid.count >= 2 else {
            return .fallback
        }
        valid.sort()
        let p02 = percentile(sorted: valid, quantile: 0.02)
        let p98 = percentile(sorted: valid, quantile: 0.98)
        let range = DepthRange(near: p02, far: p98)
        if range.isUsable {
            return range
        }
        let fallbackRange = DepthRange(near: valid.first ?? 0, far: valid.last ?? 1)
        return fallbackRange.isUsable ? fallbackRange : .fallback
    }

    static func globalRange(from ranges: [DepthRange]) -> DepthRange {
        let usable = ranges.filter(\.isUsable)
        guard !usable.isEmpty else {
            return .fallback
        }

        var nearValues = usable.map(\.near).sorted()
        var farValues = usable.map(\.far).sorted()
        let near = percentile(sorted: nearValues, quantile: 0.10)
        let far = percentile(sorted: farValues, quantile: 0.90)
        let range = DepthRange(near: near, far: far)
        if range.isUsable {
            return range
        }

        nearValues.sort()
        farValues.sort()
        let broad = DepthRange(near: nearValues.first ?? 0, far: farValues.last ?? 1)
        return broad.isUsable ? broad : .fallback
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }

    private static func percentile(sorted values: [Float], quantile: Double) -> Float {
        guard !values.isEmpty else {
            return .nan
        }
        let clamped = min(1.0, max(0.0, quantile))
        let position = clamped * Double(values.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        if lower == upper {
            return values[lower]
        }
        let fraction = Float(position - Double(lower))
        return values[lower] + (values[upper] - values[lower]) * fraction
    }
}
