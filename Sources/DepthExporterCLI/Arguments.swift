import Foundation

enum ComputeMode: String, CaseIterable {
    case all
    case cpuAndGPU
    case cpuAndNeuralEngine
    case cpuOnly
}

enum DepthFormat: String, CaseIterable {
    case grayscale
    case inverseGrayscale = "inverse-grayscale"
}

enum NormalizationMode: String, CaseIterable {
    case global
    case ema
    case perFrame = "per-frame"
}

enum ModelResizeMode: String, CaseIterable {
    case stretch
    case letterbox
}

enum ModelInputOption: Equatable {
    case auto
    case explicit(width: Int, height: Int)

    var description: String {
        switch self {
        case .auto:
            return "auto"
        case .explicit(let width, let height):
            return "\(width)x\(height)"
        }
    }
}

struct ExportConfig {
    let inputURL: URL
    let outputURL: URL
    let modelURL: URL
    let compute: ComputeMode
    let format: DepthFormat
    let normalize: NormalizationMode
    let modelInput: ModelInputOption
    let modelResizeMode: ModelResizeMode
    let modelShortSide: Int
    let modelSizeMultiple: Int
    let outputMaxSide: Int
    let bitrate: Int
    let sampleStep: Int
    let includeAudio: Bool
    let stackVertical: Bool
    let overwrite: Bool
    let progressJSON: Bool
    let dryRun: Bool
}

enum ParseResult {
    case help
    case run(ExportConfig)
}

enum Arguments {
    static let usage = """
    Usage:
      depth-exporter --input input.mp4 --output output-depth.mp4 --model DepthAnythingV2SmallF16.mlpackage [options]

    Required:
      --input <path>                 Input H.264 MP4 video
      --output <path>                Output MP4 depth-map video
      --model <path>                 Local Core ML .mlpackage, .mlmodel, or .mlmodelc

    Options:
      --compute <mode>               all | cpuAndGPU | cpuAndNeuralEngine | cpuOnly (default: all)
      --format <format>              grayscale | inverse-grayscale (default: grayscale)
      --normalize <mode>             global | ema | per-frame (default: global)
      --model-input <value>          auto | WIDTHxHEIGHT inference size (default: auto)
      --model-resize <mode>          stretch | letterbox before inference (default: stretch)
      --letterbox                    Alias for --model-resize letterbox
      --model-short-side <int>       Inference short side for flexible/vague models (default: 518)
      --model-size-multiple <int>    Inference dimensions multiple for flexible/vague models (default: 14)
      --output-max-side <int>        Longest output side; never upscales above source (default: 1920)
      --bitrate <int>                H.264 average bitrate (default: 12000000)
      --sample-step <int>            Sampling interval for global normalization (default: 30)
      --include-audio                Include the first source audio track (default: disabled)
      --stack-vertical               Export source video above depth map for comparison
      --overwrite                    Replace an existing output file
      --progress-json                Emit JSONL progress to stdout
      --dry-run                      Validate settings and print metadata without exporting
      --help                         Print this help
    Model sizing:
      --model-input, --model-short-side, and --model-size-multiple control Core ML inference resolution.
      --model-resize controls how decoded frames are fitted into that inference size.
      Default model resize mode is stretch, which may scale non-proportionally when aspect ratios differ.
      --output-max-side controls only the exported MP4 resolution.
      The default Depth Anything V2-style inference size uses short side 518 and multiple 14.
      Silent depth-map output is the default. Audio is included only with --include-audio.
      Stacked mode uses original audio only when --include-audio is also set.
    
    """

    static func parse(_ rawArguments: [String]) throws -> ParseResult {
        let args = Array(rawArguments.dropFirst())
        if args.contains("--help") || args.contains("-h") {
            return .help
        }

        var inputPath: String?
        var outputPath: String?
        var modelPath: String?
        var compute = ComputeMode.all
        var format = DepthFormat.grayscale
        var normalize = NormalizationMode.global
        var modelInput = ModelInputOption.auto
        var modelResizeMode = ModelResizeMode.stretch
        var modelShortSide = 518
        var modelSizeMultiple = 14
        var outputMaxSide = 1920
        var bitrate = 12_000_000
        var sampleStep = 30
        var includeAudio = false
        var stackVertical = false
        var overwrite = false
        var progressJSON = false
        var dryRun = false

        var index = 0
        while index < args.count {
            let flag = args[index]
            switch flag {
            case "--input":
                inputPath = try value(after: flag, in: args, index: &index)
            case "--output":
                outputPath = try value(after: flag, in: args, index: &index)
            case "--model":
                modelPath = try value(after: flag, in: args, index: &index)
            case "--compute":
                let raw = try value(after: flag, in: args, index: &index)
                guard let parsed = ComputeMode(rawValue: raw) else {
                    throw AppError.invalidArguments("Invalid --compute value '\(raw)'. Expected one of: \(ComputeMode.caseList).")
                }
                compute = parsed
            case "--format":
                let raw = try value(after: flag, in: args, index: &index)
                guard let parsed = DepthFormat(rawValue: raw) else {
                    throw AppError.invalidArguments("Invalid --format value '\(raw)'. Expected one of: \(DepthFormat.caseList).")
                }
                format = parsed
            case "--normalize":
                let raw = try value(after: flag, in: args, index: &index)
                guard let parsed = NormalizationMode(rawValue: raw) else {
                    throw AppError.invalidArguments("Invalid --normalize value '\(raw)'. Expected one of: \(NormalizationMode.caseList).")
                }
                normalize = parsed
            case "--model-input":
                modelInput = try parseModelInput(try value(after: flag, in: args, index: &index))
            case "--model-resize":
                let raw = try value(after: flag, in: args, index: &index)
                guard let parsed = ModelResizeMode(rawValue: raw) else {
                    throw AppError.invalidArguments("Invalid --model-resize value '\(raw)'. Expected one of: \(ModelResizeMode.caseList).")
                }
                modelResizeMode = parsed
            case "--letterbox":
                modelResizeMode = .letterbox
            case "--model-short-side":
                modelShortSide = try positiveInt(after: flag, in: args, index: &index)
            case "--model-size-multiple":
                modelSizeMultiple = try positiveInt(after: flag, in: args, index: &index)
            case "--output-max-side":
                outputMaxSide = try positiveInt(after: flag, in: args, index: &index)
            case "--bitrate":
                bitrate = try positiveInt(after: flag, in: args, index: &index)
            case "--sample-step":
                sampleStep = try positiveInt(after: flag, in: args, index: &index)
            case "--include-audio":
                includeAudio = true
            case "--stack-vertical":
                stackVertical = true
            case "--overwrite":
                overwrite = true
            case "--progress-json":
                progressJSON = true
            case "--dry-run":
                dryRun = true
            default:
                throw AppError.invalidArguments("Unknown argument '\(flag)'. Run depth-exporter --help for usage.")
            }
            index += 1
        }

        guard let inputPath else {
            throw AppError.invalidArguments("Missing required flag --input.")
        }
        guard let outputPath else {
            throw AppError.invalidArguments("Missing required flag --output.")
        }
        guard let modelPath else {
            throw AppError.invalidArguments("Missing required flag --model.")
        }

        return .run(ExportConfig(
            inputURL: URL(fileURLWithPath: inputPath).standardizedFileURL,
            outputURL: URL(fileURLWithPath: outputPath).standardizedFileURL,
            modelURL: URL(fileURLWithPath: modelPath).standardizedFileURL,
            compute: compute,
            format: format,
            normalize: normalize,
            modelInput: modelInput,
            modelResizeMode: modelResizeMode,
            modelShortSide: modelShortSide,
            modelSizeMultiple: modelSizeMultiple,
            outputMaxSide: outputMaxSide,
            bitrate: bitrate,
            sampleStep: sampleStep,
            includeAudio: includeAudio,
            stackVertical: stackVertical,
            overwrite: overwrite,
            progressJSON: progressJSON,
            dryRun: dryRun
        ))
    }

    private static func parseModelInput(_ raw: String) throws -> ModelInputOption {
        if raw == "auto" {
            return .auto
        }

        let parts = raw.lowercased().split(separator: "x", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let width = Int(parts[0]),
              let height = Int(parts[1]),
              width > 0,
              height > 0 else {
            throw AppError.invalidArguments("Invalid --model-input value '\(raw)'. Expected auto or WIDTHxHEIGHT with positive integers.")
        }
        return .explicit(width: width, height: height)
    }

    private static func value(after flag: String, in args: [String], index: inout Int) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < args.count else {
            throw AppError.invalidArguments("Missing value for \(flag).")
        }
        let value = args[valueIndex]
        guard !value.hasPrefix("--") else {
            throw AppError.invalidArguments("Missing value for \(flag).")
        }
        index = valueIndex
        return value
    }

    private static func positiveInt(after flag: String, in args: [String], index: inout Int) throws -> Int {
        let raw = try value(after: flag, in: args, index: &index)
        guard let value = Int(raw), value > 0 else {
            throw AppError.invalidArguments("\(flag) must be a positive integer.")
        }
        return value
    }
}

private extension CaseIterable where Self: RawRepresentable, Self.RawValue == String {
    static var caseList: String {
        allCases.map(\.rawValue).joined(separator: ", ")
    }
}
