import CoreGraphics
import CoreML
import Foundation

struct ModelInputSpec {
    let width: Int
    let height: Int
    let source: ModelInputSpecSource
    let resizeMode: ModelResizeMode
    let aspectRatioMismatch: Bool
    let requiresLetterbox: Bool
    let warnings: [String]

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var dictionary: [String: Any] {
        [
            "width": width,
            "height": height,
            "source": source.rawValue,
            "resizeMode": resizeMode.rawValue,
            "aspectRatioMismatch": aspectRatioMismatch,
            "requiresLetterbox": requiresLetterbox,
            "warnings": warnings
        ]
    }
}

enum ModelInputSpecSource: String {
    case explicitCLI
    case fixedModelConstraint
    case enumeratedModelConstraint
    case flexibleModelConstraint
    case depthAnythingDefault
}

enum ModelInputResolver {
    private static let aspectTolerance = 0.01

    static func resolve(
        option: ModelInputOption,
        sourceDisplaySize: CGSize,
        imageConstraint: MLImageConstraint?,
        resizeMode: ModelResizeMode,
        modelShortSide: Int,
        modelSizeMultiple: Int
    ) throws -> ModelInputSpec {
        guard modelShortSide > 0 else {
            throw AppError.invalidArguments("--model-short-side must be a positive integer.")
        }
        guard modelSizeMultiple > 0 else {
            throw AppError.invalidArguments("--model-size-multiple must be a positive integer.")
        }

        switch option {
        case .explicit(let width, let height):
            return try explicitSpec(
                width: width,
                height: height,
                sourceDisplaySize: sourceDisplaySize,
                imageConstraint: imageConstraint,
                resizeMode: resizeMode,
                modelSizeMultiple: modelSizeMultiple
            )
        case .auto:
            return try autoSpec(
                sourceDisplaySize: sourceDisplaySize,
                imageConstraint: imageConstraint,
                resizeMode: resizeMode,
                modelShortSide: modelShortSide,
                modelSizeMultiple: modelSizeMultiple
            )
        }
    }

    static func defaultDepthAnythingSize(
        sourceDisplaySize: CGSize,
        shortSide: Int,
        multiple: Int
    ) -> CGSize {
        PixelBufferPool.modelInputSize(
            for: sourceDisplaySize,
            shortSide: shortSide,
            multiple: multiple
        )
    }

    #if DEBUG
    static func runDebugAssertions() {
        assert(defaultDepthAnythingSize(sourceDisplaySize: CGSize(width: 1920, height: 1080), shortSide: 518, multiple: 14) == CGSize(width: 924, height: 518))
        assert(defaultDepthAnythingSize(sourceDisplaySize: CGSize(width: 1080, height: 1920), shortSide: 518, multiple: 14) == CGSize(width: 518, height: 924))
        assert(defaultDepthAnythingSize(sourceDisplaySize: CGSize(width: 3840, height: 2160), shortSide: 518, multiple: 14) == CGSize(width: 924, height: 518))
        assert(defaultDepthAnythingSize(sourceDisplaySize: CGSize(width: 1280, height: 720), shortSide: 518, multiple: 14) == CGSize(width: 924, height: 518))
        assert(defaultDepthAnythingSize(sourceDisplaySize: CGSize(width: 720, height: 1280), shortSide: 518, multiple: 14) == CGSize(width: 518, height: 924))
    }
    #endif

    private static func explicitSpec(
        width: Int,
        height: Int,
        sourceDisplaySize: CGSize,
        imageConstraint: MLImageConstraint?,
        resizeMode: ModelResizeMode,
        modelSizeMultiple: Int
    ) throws -> ModelInputSpec {
        guard width > 0, height > 0 else {
            throw AppError.invalidArguments("--model-input dimensions must be positive.")
        }

        try validateExplicitSize(width: width, height: height, imageConstraint: imageConstraint)

        var warnings: [String] = []
        if !width.isMultiple(of: modelSizeMultiple) || !height.isMultiple(of: modelSizeMultiple) {
            warnings.append("--model-input \(width)x\(height) is not divisible by --model-size-multiple \(modelSizeMultiple).")
        }

        let mismatch = aspectMismatch(sourceDisplaySize, CGSize(width: width, height: height))
        return ModelInputSpec(
            width: width,
            height: height,
            source: .explicitCLI,
            resizeMode: resizeMode,
            aspectRatioMismatch: mismatch,
            requiresLetterbox: resizeMode == .letterbox && mismatch,
            warnings: warnings
        )
    }

    private static func autoSpec(
        sourceDisplaySize: CGSize,
        imageConstraint: MLImageConstraint?,
        resizeMode: ModelResizeMode,
        modelShortSide: Int,
        modelSizeMultiple: Int
    ) throws -> ModelInputSpec {
        if let fixed = fixedSize(from: imageConstraint) {
            let mismatch = aspectMismatch(sourceDisplaySize, CGSize(width: fixed.width, height: fixed.height))
            return ModelInputSpec(
                width: fixed.width,
                height: fixed.height,
                source: .fixedModelConstraint,
                resizeMode: resizeMode,
                aspectRatioMismatch: mismatch,
                requiresLetterbox: resizeMode == .letterbox && mismatch,
                warnings: []
            )
        }

        if let constraint = imageConstraint {
            switch constraint.sizeConstraint.type {
            case .enumerated:
                let sizes = constraint.sizeConstraint.enumeratedImageSizes
                if !sizes.isEmpty {
                    let chosen = closestEnumeratedSize(
                        to: sourceDisplaySize,
                        sizes: sizes,
                        requestedShortSide: modelShortSide
                    )
                    return ModelInputSpec(
                        width: chosen.width,
                        height: chosen.height,
                        source: .enumeratedModelConstraint,
                        resizeMode: resizeMode,
                        aspectRatioMismatch: aspectMismatch(sourceDisplaySize, CGSize(width: chosen.width, height: chosen.height)),
                        requiresLetterbox: resizeMode == .letterbox && aspectMismatch(sourceDisplaySize, CGSize(width: chosen.width, height: chosen.height)),
                        warnings: []
                    )
                }
            case .range:
                let size = flexibleSize(
                    sourceDisplaySize: sourceDisplaySize,
                    modelShortSide: modelShortSide,
                    modelSizeMultiple: modelSizeMultiple,
                    imageConstraint: constraint
                )
                return ModelInputSpec(
                    width: size.width,
                    height: size.height,
                    source: .flexibleModelConstraint,
                    resizeMode: resizeMode,
                    aspectRatioMismatch: false,
                    requiresLetterbox: false,
                    warnings: []
                )
            case .unspecified:
                break
            @unknown default:
                break
            }
        }

        let size = defaultDepthAnythingSize(
            sourceDisplaySize: sourceDisplaySize,
            shortSide: modelShortSide,
            multiple: modelSizeMultiple
        )
        return ModelInputSpec(
            width: Int(size.width.rounded()),
            height: Int(size.height.rounded()),
            source: .depthAnythingDefault,
            resizeMode: resizeMode,
            aspectRatioMismatch: false,
            requiresLetterbox: false,
            warnings: []
        )
    }

    private static func validateExplicitSize(
        width: Int,
        height: Int,
        imageConstraint: MLImageConstraint?
    ) throws {
        guard let imageConstraint else {
            return
        }

        if let fixed = fixedSize(from: imageConstraint) {
            guard fixed.width == width, fixed.height == height else {
                throw AppError.validation("--model-input \(width)x\(height) is incompatible with fixed model input \(fixed.width)x\(fixed.height).")
            }
            return
        }

        switch imageConstraint.sizeConstraint.type {
        case .enumerated:
            let sizes = imageConstraint.sizeConstraint.enumeratedImageSizes
            guard sizes.isEmpty || sizes.contains(where: { $0.pixelsWide == width && $0.pixelsHigh == height }) else {
                let allowed = sizes.map { "\($0.pixelsWide)x\($0.pixelsHigh)" }.joined(separator: ", ")
                throw AppError.validation("--model-input \(width)x\(height) is not one of the model's allowed sizes: \(allowed).")
            }
        case .range:
            let widthRange = DimensionRange(imageConstraint.sizeConstraint.pixelsWideRange)
            let heightRange = DimensionRange(imageConstraint.sizeConstraint.pixelsHighRange)
            guard widthRange?.contains(width) ?? true,
                  heightRange?.contains(height) ?? true else {
                throw AppError.validation("--model-input \(width)x\(height) is outside the model input range.")
            }
        case .unspecified:
            return
        @unknown default:
            return
        }
    }

    private static func fixedSize(from imageConstraint: MLImageConstraint?) -> (width: Int, height: Int)? {
        guard let imageConstraint else {
            return nil
        }

        switch imageConstraint.sizeConstraint.type {
        case .enumerated:
            let sizes = imageConstraint.sizeConstraint.enumeratedImageSizes
            if sizes.count == 1, let size = sizes.first {
                return (size.pixelsWide, size.pixelsHigh)
            }
        case .range:
            let widthRange = DimensionRange(imageConstraint.sizeConstraint.pixelsWideRange)
            let heightRange = DimensionRange(imageConstraint.sizeConstraint.pixelsHighRange)
            if let widthRange, let heightRange,
               widthRange.isSingleValue,
               heightRange.isSingleValue,
               let width = widthRange.min,
               let height = heightRange.min {
                return (width, height)
            }
        case .unspecified:
            if imageConstraint.pixelsWide > 0, imageConstraint.pixelsHigh > 0 {
                return (imageConstraint.pixelsWide, imageConstraint.pixelsHigh)
            }
        @unknown default:
            break
        }

        return nil
    }

    private static func closestEnumeratedSize(
        to sourceDisplaySize: CGSize,
        sizes: [MLImageSize],
        requestedShortSide: Int
    ) -> (width: Int, height: Int) {
        let sourceAspect = aspect(sourceDisplaySize)

        let best = sizes.min { lhs, rhs in
            let lhsShort = min(lhs.pixelsWide, lhs.pixelsHigh)
            let rhsShort = min(rhs.pixelsWide, rhs.pixelsHigh)
            let lhsAspect = Double(lhs.pixelsWide) / max(1.0, Double(lhs.pixelsHigh))
            let rhsAspect = Double(rhs.pixelsWide) / max(1.0, Double(rhs.pixelsHigh))
            let lhsArea = Double(lhs.pixelsWide * lhs.pixelsHigh)
            let rhsArea = Double(rhs.pixelsWide * rhs.pixelsHigh)
            let lhsScore = abs(lhsAspect - sourceAspect) * 10_000
                + Double(abs(lhsShort - requestedShortSide)) * 4
                + lhsArea / 1_000_000
            let rhsScore = abs(rhsAspect - sourceAspect) * 10_000
                + Double(abs(rhsShort - requestedShortSide)) * 4
                + rhsArea / 1_000_000
            return lhsScore < rhsScore
        }

        guard let best else {
            return (max(1, requestedShortSide), max(1, requestedShortSide))
        }
        return (best.pixelsWide, best.pixelsHigh)
    }

    private static func flexibleSize(
        sourceDisplaySize: CGSize,
        modelShortSide: Int,
        modelSizeMultiple: Int,
        imageConstraint: MLImageConstraint
    ) -> (width: Int, height: Int) {
        let preferred = defaultDepthAnythingSize(
            sourceDisplaySize: sourceDisplaySize,
            shortSide: modelShortSide,
            multiple: modelSizeMultiple
        )

        let widthRange = DimensionRange(imageConstraint.sizeConstraint.pixelsWideRange)
        let heightRange = DimensionRange(imageConstraint.sizeConstraint.pixelsHighRange)
        let width = roundedClampedToMultiple(
            Int(preferred.width.rounded()),
            multiple: modelSizeMultiple,
            range: widthRange
        )
        let height = roundedClampedToMultiple(
            Int(preferred.height.rounded()),
            multiple: modelSizeMultiple,
            range: heightRange
        )
        return (max(1, width), max(1, height))
    }

    private static func roundedClampedToMultiple(
        _ value: Int,
        multiple: Int,
        range: DimensionRange?
    ) -> Int {
        let rounded = PixelBufferPool.nearestMultiple(of: multiple, to: value)
        guard let range else {
            return rounded
        }
        if range.contains(rounded) {
            return rounded
        }

        let clamped = range.clamp(rounded)
        let down = max(multiple, (clamped / multiple) * multiple)
        let up = max(multiple, ((clamped + multiple - 1) / multiple) * multiple)
        let candidates = [down, up, clamped].filter { $0 > 0 && range.contains($0) }
        return candidates.min { abs($0 - value) < abs($1 - value) } ?? clamped
    }

    private static func aspectMismatch(_ source: CGSize, _ destination: CGSize) -> Bool {
        abs(aspect(source) - aspect(destination)) > aspectTolerance
    }

    private static func aspect(_ size: CGSize) -> Double {
        Double(max(1, size.width)) / Double(max(1, size.height))
    }
}

private struct DimensionRange {
    let min: Int?
    let max: Int?

    init?(_ range: NSRange) {
        guard range.location != NSNotFound, range.length > 0 else {
            return nil
        }
        min = range.location
        if range.length >= Int.max - range.location {
            max = nil
        } else {
            max = range.location + range.length - 1
        }
    }

    var isSingleValue: Bool {
        min != nil && min == max
    }

    func contains(_ value: Int) -> Bool {
        if let min, value < min {
            return false
        }
        if let max, value > max {
            return false
        }
        return true
    }

    func clamp(_ value: Int) -> Int {
        var result = value
        if let min {
            result = Swift.max(result, min)
        }
        if let max {
            result = Swift.min(result, max)
        }
        return result
    }
}
