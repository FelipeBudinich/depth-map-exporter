import CoreML
import CoreVideo
import Foundation

enum DepthOutput {
    case pixelBuffer(CVPixelBuffer)
    case multiArray(MLMultiArray)
}

final class DepthModel {
    private let model: MLModel
    let inputName: String
    private let inputImageConstraint: MLImageConstraint?
    private let outputCandidates: [String]
    let outputName: String
    let compiledModelURL: URL

    init(modelURL: URL, computeMode: ComputeMode) throws {
        let compiledURL = try Self.cachedCompiledModelURL(for: modelURL)
        let configuration = MLModelConfiguration()
        configuration.computeUnits = computeMode.mlComputeUnits
        do {
            model = try MLModel(contentsOf: compiledURL, configuration: configuration)
        } catch {
            throw AppError.coreML("Could not load Core ML model: \(error.localizedDescription)")
        }
        compiledModelURL = compiledURL

        guard let imageInput = model.modelDescription.inputDescriptionsByName
            .sorted(by: { $0.key < $1.key })
            .first(where: { $0.value.type == .image }) else {
            throw AppError.coreML("Model does not expose an image input.")
        }
        inputName = imageInput.key
        inputImageConstraint = imageInput.value.imageConstraint

        let outputs = model.modelDescription.outputDescriptionsByName.sorted(by: { $0.key < $1.key })
        let imageOutputs = outputs.filter { $0.value.type == .image }.map(\.key)
        let multiArrayOutputs = outputs.filter { $0.value.type == .multiArray }.map(\.key)
        let candidates = imageOutputs + multiArrayOutputs + outputs.map(\.key).filter { name in
            !(imageOutputs + multiArrayOutputs).contains(name)
        }

        guard let firstCandidate = candidates.first else {
            throw AppError.coreML("Model does not expose any outputs.")
        }
        outputCandidates = candidates
        outputName = firstCandidate
    }

    func predictDepth(from pixelBuffer: CVPixelBuffer) throws -> DepthOutput {
        let provider: MLDictionaryFeatureProvider
        do {
            provider = try MLDictionaryFeatureProvider(dictionary: [
                inputName: MLFeatureValue(pixelBuffer: pixelBuffer)
            ])
        } catch {
            throw AppError.coreML("Could not create Core ML input: \(error.localizedDescription)")
        }

        let prediction: MLFeatureProvider
        do {
            prediction = try model.prediction(from: provider)
        } catch {
            throw AppError.coreML("Core ML prediction failed: \(error.localizedDescription)")
        }

        for name in outputCandidates {
            guard let feature = prediction.featureValue(for: name) else {
                continue
            }
            if let pixelBuffer = feature.imageBufferValue {
                return .pixelBuffer(pixelBuffer)
            }
            if let multiArray = feature.multiArrayValue {
                return .multiArray(multiArray)
            }
        }

        throw AppError.coreML("No usable depth output was produced. Expected an image buffer or MLMultiArray.")
    }

    var imageInputConstraint: MLImageConstraint? {
        inputImageConstraint
    }

    var dictionary: [String: Any] {
        [
            "compiledModelPath": compiledModelURL.path,
            "inputName": inputName,
            "outputName": outputName,
            "inputs": descriptionsDictionary(model.modelDescription.inputDescriptionsByName),
            "outputs": descriptionsDictionary(model.modelDescription.outputDescriptionsByName)
        ]
    }

    private func descriptionsDictionary(_ descriptions: [String: MLFeatureDescription]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (name, description) in descriptions.sorted(by: { $0.key < $1.key }) {
            var entry: [String: Any] = [
                "type": description.type.readableName,
                "optional": description.isOptional
            ]
            if let image = description.imageConstraint {
                entry["image"] = [
                    "width": image.pixelsWide,
                    "height": image.pixelsHigh,
                    "pixelFormatType": image.pixelFormatType,
                    "sizeConstraint": image.sizeConstraint.dictionary
                ]
            }
            if let array = description.multiArrayConstraint {
                entry["multiArray"] = [
                    "shape": array.shape.map { $0.intValue },
                    "dataType": array.dataType.readableName
                ]
            }
            result[name] = entry
        }
        return result
    }

    private static func cachedCompiledModelURL(for modelURL: URL) throws -> URL {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelURL.path) else {
            throw AppError.validation("Model does not exist: \(modelURL.path)")
        }

        if modelURL.pathExtension == "mlmodelc" {
            return modelURL
        }

        let cacheDirectory = try cacheDirectoryURL()
        let fingerprint = try modelFingerprint(modelURL)
        let baseName = modelURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let destination = cacheDirectory
            .appendingPathComponent("\(baseName)-\(fingerprint)")
            .appendingPathExtension("mlmodelc")

        if fileManager.fileExists(atPath: destination.path) {
            return destination
        }

        let compiled: URL
        do {
            compiled = try MLModel.compileModel(at: modelURL)
        } catch {
            throw AppError.coreML("Could not compile Core ML model: \(error.localizedDescription)")
        }

        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: compiled, to: destination)
        } catch {
            throw AppError.coreML("Could not cache compiled model under \(cacheDirectory.path): \(error.localizedDescription)")
        }

        return destination
    }

    private static func cacheDirectoryURL() throws -> URL {
        let fileManager = FileManager.default
        let base = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("depth-exporter", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func modelFingerprint(_ url: URL) throws -> String {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw AppError.validation("Model does not exist: \(url.path)")
        }

        var payload = url.standardizedFileURL.path
        var totalSize: UInt64 = 0
        var latestModified: TimeInterval = 0

        let urls: [URL]
        if isDirectory.boolValue {
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            urls = (enumerator?.compactMap { $0 as? URL } ?? []) + [url]
        } else {
            urls = [url]
        }

        for item in urls {
            let values = try item.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            totalSize += UInt64(values.fileSize ?? 0)
            latestModified = max(latestModified, values.contentModificationDate?.timeIntervalSince1970 ?? 0)
        }

        payload += "|\(totalSize)|\(latestModified)"
        return fnv1a64(payload)
    }

    private static func fnv1a64(_ text: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return String(format: "%016llx", hash)
    }

}

private extension ComputeMode {
    var mlComputeUnits: MLComputeUnits {
        switch self {
        case .all:
            return .all
        case .cpuAndGPU:
            return .cpuAndGPU
        case .cpuAndNeuralEngine:
            return .cpuAndNeuralEngine
        case .cpuOnly:
            return .cpuOnly
        }
    }
}

private extension MLFeatureType {
    var readableName: String {
        switch self {
        case .invalid:
            return "invalid"
        case .int64:
            return "int64"
        case .double:
            return "double"
        case .string:
            return "string"
        case .image:
            return "image"
        case .multiArray:
            return "multiArray"
        case .dictionary:
            return "dictionary"
        case .sequence:
            return "sequence"
        case .state:
            return "state"
        @unknown default:
            return "unknown"
        }
    }
}

private extension MLMultiArrayDataType {
    var readableName: String {
        switch self {
        case .double:
            return "double"
        case .float32:
            return "float32"
        case .float16:
            return "float16"
        case .int32:
            return "int32"
        case .int8:
            return "int8"
        @unknown default:
            return "unknown"
        }
    }
}

private extension MLImageSizeConstraint {
    var dictionary: [String: Any] {
        var result: [String: Any] = [
            "type": type.readableName
        ]

        if type == .enumerated {
            result["enumerated"] = enumeratedImageSizes.map {
                [
                    "width": $0.pixelsWide,
                    "height": $0.pixelsHigh
                ]
            }
        }

        if type == .range {
            result["widthRange"] = [
                "location": pixelsWideRange.location,
                "length": pixelsWideRange.length
            ]
            result["heightRange"] = [
                "location": pixelsHighRange.location,
                "length": pixelsHighRange.length
            ]
        }

        return result
    }
}

private extension MLImageSizeConstraintType {
    var readableName: String {
        switch self {
        case .unspecified:
            return "unspecified"
        case .enumerated:
            return "enumerated"
        case .range:
            return "range"
        @unknown default:
            return "unknown"
        }
    }
}
