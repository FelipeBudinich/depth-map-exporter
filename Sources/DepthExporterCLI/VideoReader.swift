import AVFoundation
import CoreVideo
import Foundation

struct VideoFrame {
    let pixelBuffer: CVPixelBuffer
    let presentationTime: CMTime
    let index: Int
}

final class VideoReader {
    private let reader: AVAssetReader
    private let output: AVAssetReaderOutput
    private var frameIndex = 0

    init(inputURL: URL, metadata: VideoMetadata) throws {
        let asset = AVURLAsset(url: inputURL)
        guard let track = asset.tracks(withMediaType: .video).first else {
            throw AppError.validation("Input does not contain a video track: \(inputURL.path)")
        }

        reader = try AVAssetReader(asset: asset)
        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        if metadata.preferredTransform.isIdentity {
            let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
            trackOutput.alwaysCopiesSampleData = false
            output = trackOutput
        } else {
            let compositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: [track], videoSettings: settings)
            compositionOutput.alwaysCopiesSampleData = false
            compositionOutput.videoComposition = Self.videoComposition(asset: asset, track: track, metadata: metadata)
            output = compositionOutput
        }

        guard reader.canAdd(output) else {
            throw AppError.videoIO("Could not add video reader output.")
        }
        reader.add(output)

        guard reader.startReading() else {
            throw AppError.videoIO("Could not start video reader: \(reader.error?.localizedDescription ?? "unknown error")")
        }
    }

    func nextFrame() throws -> VideoFrame? {
        guard let sampleBuffer = output.copyNextSampleBuffer() else {
            if reader.status == .failed {
                throw AppError.videoIO("Video reader failed: \(reader.error?.localizedDescription ?? "unknown error")")
            }
            return nil
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw AppError.videoIO("Could not get pixel buffer for frame \(frameIndex).")
        }

        let frame = VideoFrame(
            pixelBuffer: pixelBuffer,
            presentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
            index: frameIndex
        )
        frameIndex += 1
        return frame
    }

    func cancel() {
        reader.cancelReading()
    }

    private static func videoComposition(asset: AVAsset, track: AVAssetTrack, metadata: VideoMetadata) -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition()
        composition.renderSize = metadata.displaySize
        if metadata.nominalFPS > 0 {
            composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(max(1, Int32(metadata.nominalFPS.rounded()))))
        } else {
            composition.frameDuration = CMTime(value: 1, timescale: 30)
        }

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let rect = CGRect(origin: .zero, size: track.naturalSize).applying(track.preferredTransform)
        var transform = track.preferredTransform
        transform.tx -= rect.origin.x
        transform.ty -= rect.origin.y
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        return composition
    }
}
