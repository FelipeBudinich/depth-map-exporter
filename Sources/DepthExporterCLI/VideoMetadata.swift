import AVFoundation
import CoreMedia
import Foundation

struct VideoMetadata {
    let duration: CMTime
    let nominalFPS: Double
    let estimatedFrameCount: Int
    let sourceSize: CGSize
    let displaySize: CGSize
    let preferredTransform: CGAffineTransform
    let codecInfo: String
    let audioTrackDetected: Bool

    var dictionary: [String: Any] {
        [
            "durationSeconds": duration.seconds.isFinite ? duration.seconds : 0,
            "nominalFPS": nominalFPS,
            "estimatedFrameCount": estimatedFrameCount,
            "sourceWidth": Int(sourceSize.width.rounded()),
            "sourceHeight": Int(sourceSize.height.rounded()),
            "displayWidth": Int(displaySize.width.rounded()),
            "displayHeight": Int(displaySize.height.rounded()),
            "preferredTransform": [
                "a": preferredTransform.a,
                "b": preferredTransform.b,
                "c": preferredTransform.c,
                "d": preferredTransform.d,
                "tx": preferredTransform.tx,
                "ty": preferredTransform.ty
            ],
            "codec": codecInfo,
            "audioTrackDetected": audioTrackDetected
        ]
    }

    static func load(from url: URL) throws -> VideoMetadata {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else {
            throw AppError.validation("Input does not contain a video track: \(url.path)")
        }

        let sourceSize = track.naturalSize
        let transform = track.preferredTransform
        let displaySize = orientedSize(naturalSize: sourceSize, transform: transform)
        let fps = frameRate(for: track)
        let duration = asset.duration
        let seconds = duration.seconds.isFinite ? duration.seconds : 0
        let estimatedFrames = fps > 0 ? max(1, Int((seconds * fps).rounded())) : 0
        let codec = codecInfo(for: track)
        let hasAudio = !asset.tracks(withMediaType: .audio).isEmpty

        return VideoMetadata(
            duration: duration,
            nominalFPS: fps,
            estimatedFrameCount: estimatedFrames,
            sourceSize: sourceSize,
            displaySize: displaySize,
            preferredTransform: transform,
            codecInfo: codec,
            audioTrackDetected: hasAudio
        )
    }

    static func orientedSize(naturalSize: CGSize, transform: CGAffineTransform) -> CGSize {
        let rect = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return CGSize(width: abs(rect.width).rounded(), height: abs(rect.height).rounded())
    }

    private static func frameRate(for track: AVAssetTrack) -> Double {
        if track.nominalFrameRate > 0 {
            return Double(track.nominalFrameRate)
        }
        if track.minFrameDuration.isValid && track.minFrameDuration.seconds > 0 {
            return 1.0 / track.minFrameDuration.seconds
        }
        return 0
    }

    private static func codecInfo(for track: AVAssetTrack) -> String {
        let descriptions = track.formatDescriptions
        let names = descriptions.compactMap { description -> String? in
            let formatDescription = description as! CMFormatDescription
            return fourCCString(CMFormatDescriptionGetMediaSubType(formatDescription))
        }
        return names.isEmpty ? "unknown" : names.joined(separator: ",")
    }

    private static func fourCCString(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff)
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? "\(code)"
    }
}
