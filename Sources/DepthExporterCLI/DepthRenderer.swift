import CoreImage
import CoreVideo
import Foundation
import Metal

final class DepthRenderer {
    private let ciContext: CIContext
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            ciContext = CIContext(mtlDevice: device)
        } else {
            ciContext = CIContext()
        }
    }

    func renderInputFrame(_ source: CVPixelBuffer, to destination: CVPixelBuffer, spec: ModelInputSpec) throws {
        let image = CIImage(cvPixelBuffer: source)
        let targetWidth = CGFloat(CVPixelBufferGetWidth(destination))
        let targetHeight = CGFloat(CVPixelBufferGetHeight(destination))
        let bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

        if spec.requiresLetterbox {
            let background = CIImage(color: .black).cropped(to: bounds)
            ciContext.render(background, to: destination, bounds: bounds, colorSpace: colorSpace)

            let scale = min(
                targetWidth / max(1, image.extent.width),
                targetHeight / max(1, image.extent.height)
            )
            let scaledWidth = image.extent.width * scale
            let scaledHeight = image.extent.height * scale
            let offsetX = (targetWidth - scaledWidth) / 2
            let offsetY = (targetHeight - scaledHeight) / 2
            let scaled = lanczosScaled(
                image,
                targetWidth: scaledWidth,
                targetHeight: scaledHeight,
                offsetX: offsetX,
                offsetY: offsetY
            )
            ciContext.render(scaled, to: destination, bounds: bounds, colorSpace: colorSpace)
        } else {
            let scaled = lanczosScaled(
                image,
                targetWidth: targetWidth,
                targetHeight: targetHeight,
                offsetX: 0,
                offsetY: 0
            )
            ciContext.render(scaled, to: destination, bounds: bounds, colorSpace: colorSpace)
        }
    }

    func renderDepth(_ grid: DepthGrid, range: DepthRange, format: DepthFormat, to destination: CVPixelBuffer) throws {
        let outputWidth = CVPixelBufferGetWidth(destination)
        let outputHeight = CVPixelBufferGetHeight(destination)
        let usableRange = range.isUsable ? range : DepthRange.fallback
        let denominator = max(0.000001, usableRange.far - usableRange.near)
        let invert = format == .inverseGrayscale

        CVPixelBufferLockBaseAddress(destination, [])
        defer { CVPixelBufferUnlockBaseAddress(destination, []) }

        guard let base = CVPixelBufferGetBaseAddress(destination) else {
            throw AppError.videoIO("Output pixel buffer has no base address.")
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(destination)
        for y in 0..<outputHeight {
            let row = base.advanced(by: y * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<outputWidth {
                var normalized = (sample(grid: grid, outputX: x, outputY: y, outputWidth: outputWidth, outputHeight: outputHeight) - usableRange.near) / denominator
                if !normalized.isFinite {
                    normalized = 0
                }
                normalized = min(1, max(0, normalized))
                if invert {
                    normalized = 1 - normalized
                }
                let byte = UInt8((normalized * 255).rounded())
                let offset = x * 4
                row[offset] = byte
                row[offset + 1] = byte
                row[offset + 2] = byte
                row[offset + 3] = 255
            }
        }
    }

    func renderStackedFrame(source: CVPixelBuffer, depthPanel: CVPixelBuffer, to destination: CVPixelBuffer) throws {
        let finalWidth = CGFloat(CVPixelBufferGetWidth(destination))
        let finalHeight = CGFloat(CVPixelBufferGetHeight(destination))
        let panelHeight = CGFloat(CVPixelBufferGetHeight(depthPanel))
        let panelWidth = CGFloat(CVPixelBufferGetWidth(depthPanel))
        let bounds = CGRect(x: 0, y: 0, width: finalWidth, height: finalHeight)

        let background = CIImage(color: .black).cropped(to: bounds)
        ciContext.render(background, to: destination, bounds: bounds, colorSpace: colorSpace)

        let depthImage = CIImage(cvPixelBuffer: depthPanel)
        let depth = lanczosScaled(
            depthImage,
            targetWidth: panelWidth,
            targetHeight: panelHeight,
            offsetX: 0,
            offsetY: 0
        )
        ciContext.render(depth, to: destination, bounds: bounds, colorSpace: colorSpace)

        let sourceImage = CIImage(cvPixelBuffer: source)
        let scale = min(
            panelWidth / max(1, sourceImage.extent.width),
            panelHeight / max(1, sourceImage.extent.height)
        )
        let scaledWidth = sourceImage.extent.width * scale
        let scaledHeight = sourceImage.extent.height * scale
        let offsetX = (panelWidth - scaledWidth) / 2
        let offsetY = panelHeight + (panelHeight - scaledHeight) / 2
        let top = lanczosScaled(
            sourceImage,
            targetWidth: scaledWidth,
            targetHeight: scaledHeight,
            offsetX: offsetX,
            offsetY: offsetY
        )
        ciContext.render(top, to: destination, bounds: bounds, colorSpace: colorSpace)
    }

    private func sample(grid: DepthGrid, outputX: Int, outputY: Int, outputWidth: Int, outputHeight: Int) -> Float {
        guard grid.width > 0, grid.height > 0 else {
            return 0
        }

        let sourceX = (Double(outputX) + 0.5) * Double(grid.width) / Double(outputWidth) - 0.5
        let sourceY = (Double(outputY) + 0.5) * Double(grid.height) / Double(outputHeight) - 0.5
        let rawX0 = Int(floor(sourceX))
        let rawY0 = Int(floor(sourceY))
        let x0 = min(max(rawX0, 0), grid.width - 1)
        let y0 = min(max(rawY0, 0), grid.height - 1)
        let x1 = min(max(rawX0 + 1, 0), grid.width - 1)
        let y1 = min(max(rawY0 + 1, 0), grid.height - 1)
        let tx = Float(min(1.0, max(0.0, sourceX - Double(rawX0))))
        let ty = Float(min(1.0, max(0.0, sourceY - Double(rawY0))))

        let a = valid(grid.values[y0 * grid.width + x0])
        let b = valid(grid.values[y0 * grid.width + x1])
        let c = valid(grid.values[y1 * grid.width + x0])
        let d = valid(grid.values[y1 * grid.width + x1])
        let top = a + (b - a) * tx
        let bottom = c + (d - c) * tx
        return top + (bottom - top) * ty
    }

    private func valid(_ value: Float) -> Float {
        value.isFinite ? value : 0
    }

    private func lanczosScaled(
        _ image: CIImage,
        targetWidth: CGFloat,
        targetHeight: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) -> CIImage {
        let scaleY = targetHeight / max(1, image.extent.height)
        let scaleX = targetWidth / max(1, image.extent.width)
        let aspectRatio = scaleY == 0 ? 1 : scaleX / scaleY
        let scaled = image.applyingFilter(
            "CILanczosScaleTransform",
            parameters: [
                kCIInputScaleKey: scaleY,
                kCIInputAspectRatioKey: aspectRatio
            ]
        )
        return scaled.transformed(by: CGAffineTransform(
            translationX: -scaled.extent.origin.x + offsetX,
            y: -scaled.extent.origin.y + offsetY
        ))
    }
}
