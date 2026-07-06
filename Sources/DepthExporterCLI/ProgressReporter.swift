import Foundation

final class ProgressReporter {
    private let json: Bool

    init(json: Bool) {
        self.json = json
    }

    func log(_ message: String) {
        writeStderr(message + "\n")
    }

    func progress(stage: String, frame: Int, totalFrames: Int) {
        let safeTotal = max(totalFrames, 1)
        let percent = min(100.0, max(0.0, Double(frame) / Double(safeTotal) * 100.0))
        if json {
            writeJSON([
                "type": "progress",
                "stage": stage,
                "frame": frame,
                "totalFrames": totalFrames,
                "percent": percent
            ])
        } else {
            let rounded = String(format: "%.1f", percent)
            writeStderr("[\(stage)] \(frame)/\(totalFrames) (\(rounded)%)\n")
        }
    }

    func done(totalFrames: Int) {
        progress(stage: "done", frame: totalFrames, totalFrames: totalFrames)
    }

    func dryRun(metadata: [String: Any], model: [String: Any], settings: [String: Any]) {
        if json {
            writeJSON([
                "type": "dry-run",
                "metadata": metadata,
                "model": model,
                "settings": settings
            ])
        } else {
            print("Dry run:")
            print("  Input path: \(settings["inputPath"] ?? "")")
            print("  Model path: \(settings["modelPath"] ?? "")")
            print("  Source natural size: \(metadata["sourceWidth"] ?? "?")x\(metadata["sourceHeight"] ?? "?")")
            print("  Source display size: \(metadata["displayWidth"] ?? "?")x\(metadata["displayHeight"] ?? "?")")
            print("  Preferred transform: \(metadata["preferredTransform"] ?? [:])")
            print("  Estimated frame count: \(metadata["estimatedFrameCount"] ?? "?")")
            print("  Model input size: \(settings["modelInputWidth"] ?? "?")x\(settings["modelInputHeight"] ?? "?")")
            print("  Model input source: \(settings["modelInputSource"] ?? "?")")
            print("  Model resize mode: \(settings["modelResizeMode"] ?? "?")")
            print("  Aspect ratio mismatch: \(settings["aspectRatioMismatch"] ?? "?")")
            print("  Requires letterbox: \(settings["requiresLetterbox"] ?? "?")")
            print("  Layout: \(settings["layout"] ?? "?")")
            print("  Panel size: \(settings["panelWidth"] ?? "?")x\(settings["panelHeight"] ?? "?")")
            print("  Output size: \(settings["outputWidth"] ?? "?")x\(settings["outputHeight"] ?? "?")")
            print("  Audio track detected: \(settings["audioTrackDetected"] ?? "?")")
            print("  Include audio: \(settings["includeAudio"] ?? "?")")
            print("  Audio behavior: \(settings["audioBehavior"] ?? "?")")
            print("  Model input name: \(settings["modelInputName"] ?? "?")")
            print("  Model output name: \(settings["modelOutputName"] ?? "?")")
            print("  Compute units: \(settings["compute"] ?? "?")")
            print("  Normalization mode: \(settings["normalize"] ?? "?")")
            print("  Output format: \(settings["format"] ?? "?")")
            print("  Audio: \(settings["audio"] ?? "disabled / video-only output")")
            print("")
            print("Video metadata:")
            print(pretty(metadata))
            print("")
            print("Model metadata:")
            print(pretty(model))
            print("")
            print("Export settings:")
            print(pretty(settings))
        }
    }

    private func writeJSON(_ object: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            FileHandle.standardOutput.write(data)
            FileHandle.standardOutput.write(Data("\n".utf8))
        } catch {
            writeStderr("Failed to encode progress JSON: \(error)\n")
        }
    }

    private func pretty(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            return String(describing: object)
        }
        return text
    }

    private func writeStderr(_ message: String) {
        FileHandle.standardError.write(Data(message.utf8))
    }
}
