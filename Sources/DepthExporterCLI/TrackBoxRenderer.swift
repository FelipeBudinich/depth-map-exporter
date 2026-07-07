import CoreGraphics
import CoreImage
import CoreText
import CoreVideo
import Foundation

final class TrackBoxRenderer {
    private let ciContext: CIContext
    private let outputSize: CGSize

    init(outputSize: CGSize) {
        self.outputSize = outputSize
        self.ciContext = CIContext()
    }

    func render(
        source: CVPixelBuffer,
        boxes: [TrackedBox],
        drawLabels: Bool,
        debug: Bool,
        to output: CVPixelBuffer
    ) throws {
        renderSource(source, to: output)
        try drawBoxes(boxes, drawLabels: drawLabels, debug: debug, in: output)
    }

    private func renderSource(_ source: CVPixelBuffer, to output: CVPixelBuffer) {
        let sourceWidth = CGFloat(CVPixelBufferGetWidth(source))
        let sourceHeight = CGFloat(CVPixelBufferGetHeight(source))
        let scaleX = outputSize.width / max(1, sourceWidth)
        let scaleY = outputSize.height / max(1, sourceHeight)
        let image = CIImage(cvPixelBuffer: source)
            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        ciContext.render(image, to: output, bounds: CGRect(origin: .zero, size: outputSize), colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    private func drawBoxes(
        _ boxes: [TrackedBox],
        drawLabels: Bool,
        debug: Bool,
        in output: CVPixelBuffer
    ) throws {
        CVPixelBufferLockBaseAddress(output, [])
        defer { CVPixelBufferUnlockBaseAddress(output, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(output) else {
            throw AppError.videoIO("Could not lock output buffer for box rendering.")
        }

        let width = CVPixelBufferGetWidth(output)
        let height = CVPixelBufferGetHeight(output)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(output)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw AppError.videoIO("Could not create graphics context for box rendering.")
        }

        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        for box in boxes where box.isVisible && box.rect.isFiniteRect {
            let rect = BoxGeometry.clampedToFrame(box.rect, frameSize: outputSize).integral
            guard !rect.isNull, rect.width > 1, rect.height > 1 else {
                continue
            }
            let color = cgColor(for: box.color, alpha: box.source == .deadReckoned ? 0.78 : 1.0)
            context.setStrokeColor(color)
            context.setLineWidth(box.source == .deadReckoned ? 2.5 : 4)
            if box.source == .deadReckoned || (debug && box.source == .corrected) {
                context.setLineDash(phase: 0, lengths: [10, 6])
            } else {
                context.setLineDash(phase: 0, lengths: [])
            }
            context.stroke(rect)

            if drawLabels {
                let label = debug
                    ? "\(box.color.name) \(box.trackID + 1) \(box.source.rawValue)"
                    : "\(box.color.name) \(box.trackID + 1)"
                drawLabel(label, color: color, at: rect, in: context)
            }
        }

        context.restoreGState()
    }

    private func drawLabel(_ text: String, color: CGColor, at rect: CGRect, in context: CGContext) {
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 18, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 1, alpha: 1)
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        let bounds = CTLineGetBoundsWithOptions(line, [])
        let paddingX: CGFloat = 6
        let paddingY: CGFloat = 4
        let labelWidth = min(outputSize.width - 2, ceil(bounds.width + paddingX * 2))
        let labelHeight = ceil(bounds.height + paddingY * 2 + 4)
        let originX = min(max(1, rect.minX), max(1, outputSize.width - labelWidth - 1))
        let originY = max(1, rect.minY - labelHeight - 2)
        let labelRect = CGRect(x: originX, y: originY, width: labelWidth, height: labelHeight)

        context.setFillColor(color.copy(alpha: 0.82) ?? color)
        context.fill(labelRect)

        context.saveGState()
        context.translateBy(x: labelRect.minX + paddingX, y: labelRect.maxY - paddingY - 5)
        context.scaleBy(x: 1, y: -1)
        context.textPosition = .zero
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private func cgColor(for color: TrackColor, alpha: CGFloat) -> CGColor {
        let components = color.components
        return CGColor(
            red: components.red,
            green: components.green,
            blue: components.blue,
            alpha: min(components.alpha, alpha)
        )
    }
}
