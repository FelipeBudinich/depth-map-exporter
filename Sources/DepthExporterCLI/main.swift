import Foundation
import Darwin
import CoreVideo

private func run(_ config: ExportConfig) throws {
    #if DEBUG
    ModelInputResolver.runDebugAssertions()
    #endif

    try validate(config)

    let reporter = ProgressReporter(json: config.progressJSON)
    reporter.log("Loading video metadata...")
    let metadata = try VideoMetadata.load(from: config.inputURL)
    let totalFrames = metadata.estimatedFrameCount

    reporter.progress(stage: "metadata", frame: 0, totalFrames: totalFrames)
    reporter.log("Loading Core ML model...")
    let model = try DepthModel(modelURL: config.modelURL, computeMode: config.compute)

    let modelInputSpec = try ModelInputResolver.resolve(
        option: config.modelInput,
        sourceDisplaySize: metadata.displaySize,
        imageConstraint: model.imageInputConstraint,
        resizeMode: config.modelResizeMode,
        modelShortSide: config.modelShortSide,
        modelSizeMultiple: config.modelSizeMultiple
    )
    let panelSize = PixelBufferPool.outputSize(for: metadata.displaySize, maxSide: config.outputMaxSide)
    let finalOutputSize = config.stackVertical
        ? CGSize(width: panelSize.width, height: panelSize.height * 2)
        : panelSize
    let layout = config.stackVertical ? "stacked-vertical" : "depth-only"
    let audioBehavior: String
    if config.includeAudio, metadata.audioTrackDetected {
        audioBehavior = "include first source audio track"
    } else if config.includeAudio {
        audioBehavior = "requested but no audio track found"
    } else {
        audioBehavior = "disabled"
    }

    reporter.log("Model input size: \(modelInputSpec.width)x\(modelInputSpec.height) (\(modelInputSpec.source.rawValue))")
    reporter.log("Model resize mode: \(modelInputSpec.resizeMode.rawValue)")
    reporter.log("Layout: \(layout)")
    reporter.log("Audio behavior: \(audioBehavior)")
    if modelInputSpec.requiresLetterbox {
        reporter.log("Preprocessing: aspect-fit letterbox enabled for model input.")
    } else if modelInputSpec.aspectRatioMismatch {
        reporter.log("Preprocessing: stretching frame non-proportionally to model input size.")
    }
    for warning in modelInputSpec.warnings {
        reporter.log("warning: \(warning)")
    }

    let settings: [String: Any] = [
        "inputPath": config.inputURL.path,
        "outputPath": config.outputURL.path,
        "modelPath": config.modelURL.path,
        "includeAudio": config.includeAudio,
        "stackVertical": config.stackVertical,
        "audioTrackDetected": metadata.audioTrackDetected,
        "audioBehavior": audioBehavior,
        "layout": layout,
        "compute": config.compute.rawValue,
        "format": config.format.rawValue,
        "normalize": config.normalize.rawValue,
        "modelInput": config.modelInput.description,
        "modelResize": config.modelResizeMode.rawValue,
        "modelShortSide": config.modelShortSide,
        "modelSizeMultiple": config.modelSizeMultiple,
        "modelInputWidth": modelInputSpec.width,
        "modelInputHeight": modelInputSpec.height,
        "modelInputSource": modelInputSpec.source.rawValue,
        "modelResizeMode": modelInputSpec.resizeMode.rawValue,
        "aspectRatioMismatch": modelInputSpec.aspectRatioMismatch,
        "requiresLetterbox": modelInputSpec.requiresLetterbox,
        "modelInputSpec": modelInputSpec.dictionary,
        "modelInputName": model.inputName,
        "modelOutputName": model.outputName,
        "panelWidth": Int(panelSize.width.rounded()),
        "panelHeight": Int(panelSize.height.rounded()),
        "outputWidth": Int(finalOutputSize.width.rounded()),
        "outputHeight": Int(finalOutputSize.height.rounded()),
        "bitrate": config.bitrate,
        "sampleStep": config.sampleStep,
        "overwrite": config.overwrite,
        "audio": audioBehavior
    ]

    if config.dryRun {
        reporter.dryRun(metadata: metadata.dictionary, model: model.dictionary, settings: settings)
        return
    }

    let renderer = DepthRenderer()
    let modelInputPool = try PixelBufferPool(
        width: modelInputSpec.width,
        height: modelInputSpec.height
    )
    let panelPool = try PixelBufferPool(
        width: Int(panelSize.width.rounded()),
        height: Int(panelSize.height.rounded())
    )
    let finalOutputPool = try PixelBufferPool(
        width: Int(finalOutputSize.width.rounded()),
        height: Int(finalOutputSize.height.rounded())
    )

    let globalRange: DepthRange?
    if config.normalize == .global {
        reporter.log("Sampling frames for global normalization...")
        globalRange = try sampleGlobalRange(
            config: config,
            metadata: metadata,
            model: model,
            renderer: renderer,
            modelInputPool: modelInputPool,
            modelInputSpec: modelInputSpec,
            reporter: reporter
        )
        if let globalRange {
            reporter.log("Global range near=\(globalRange.near) far=\(globalRange.far)")
        }
    } else {
        globalRange = nil
    }

    reporter.log("Writing depth video...")
    let writer = try VideoWriter(
        outputURL: config.outputURL,
        outputSize: finalOutputSize,
        bitrate: config.bitrate,
        overwrite: config.overwrite,
        inputURL: config.inputURL,
        includeAudio: config.includeAudio,
        duration: metadata.duration
    )
    if let audioMessage = writer.audioMessage {
        reporter.log(audioMessage)
    }
    let reader = try VideoReader(inputURL: config.inputURL, metadata: metadata)
    let normalizer = DepthNormalizer()
    var processedFrames = 0

    while let frame = try reader.nextFrame() {
        try autoreleasepool {
            let modelInput = try modelInputPool.makePixelBuffer()
            try renderer.renderInputFrame(frame.pixelBuffer, to: modelInput, spec: modelInputSpec)
            let depthOutput = try model.predictDepth(from: modelInput)
            let depthGrid = try DepthGrid(output: depthOutput)
            let range: DepthRange
            if let globalRange {
                range = globalRange
            } else {
                range = normalizer.range(for: depthGrid, mode: config.normalize)
            }

            let depthPanel = try panelPool.makePixelBuffer()
            try renderer.renderDepth(depthGrid, range: range, format: config.format, to: depthPanel)
            let outputBuffer: CVPixelBuffer
            if config.stackVertical {
                let stacked = try finalOutputPool.makePixelBuffer()
                try renderer.renderStackedFrame(source: frame.pixelBuffer, depthPanel: depthPanel, to: stacked)
                outputBuffer = stacked
            } else {
                outputBuffer = depthPanel
            }
            try writer.append(pixelBuffer: outputBuffer, presentationTime: frame.presentationTime)
            processedFrames += 1

            if processedFrames == 1 || processedFrames.isMultiple(of: 30) {
                reporter.progress(stage: "processing", frame: processedFrames, totalFrames: totalFrames)
            }
        }
    }

    try writer.finish()
    reporter.done(totalFrames: max(processedFrames, totalFrames))
    reporter.log("Wrote \(processedFrames) frames to \(config.outputURL.path)")
}

private func sampleGlobalRange(
    config: ExportConfig,
    metadata: VideoMetadata,
    model: DepthModel,
    renderer: DepthRenderer,
    modelInputPool: PixelBufferPool,
    modelInputSpec: ModelInputSpec,
    reporter: ProgressReporter
) throws -> DepthRange {
    let reader = try VideoReader(inputURL: config.inputURL, metadata: metadata)
    defer { reader.cancel() }

    var ranges: [DepthRange] = []
    var lastReportedFrame = -1

    while let frame = try reader.nextFrame() {
        if frame.index.isMultiple(of: config.sampleStep) {
            try autoreleasepool {
                let modelInput = try modelInputPool.makePixelBuffer()
                try renderer.renderInputFrame(frame.pixelBuffer, to: modelInput, spec: modelInputSpec)
                let depthOutput = try model.predictDepth(from: modelInput)
                let depthGrid = try DepthGrid(output: depthOutput)
                ranges.append(DepthNormalizer.percentileRange(for: depthGrid))
            }
        }

        if frame.index == 0 || frame.index - lastReportedFrame >= max(config.sampleStep, 30) {
            lastReportedFrame = frame.index
            reporter.progress(stage: "sampling", frame: frame.index, totalFrames: metadata.estimatedFrameCount)
        }
    }

    guard !ranges.isEmpty else {
        throw AppError.videoIO("No frames were sampled for global normalization.")
    }
    return DepthNormalizer.globalRange(from: ranges)
}

private func validate(_ config: ExportConfig) throws {
    let fileManager = FileManager.default

    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: config.inputURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
        throw AppError.validation("Input video does not exist: \(config.inputURL.path)")
    }
    guard config.inputURL.pathExtension.lowercased() == "mp4" else {
        throw AppError.validation("Input must be a local .mp4 file: \(config.inputURL.path)")
    }

    guard fileManager.fileExists(atPath: config.modelURL.path, isDirectory: &isDirectory) else {
        throw AppError.validation("Model does not exist: \(config.modelURL.path)")
    }

    let outputDirectory = config.outputURL.deletingLastPathComponent()
    guard fileManager.fileExists(atPath: outputDirectory.path, isDirectory: &isDirectory), isDirectory.boolValue else {
        throw AppError.validation("Output directory does not exist: \(outputDirectory.path)")
    }
    if fileManager.fileExists(atPath: config.outputURL.path), !config.overwrite {
        throw AppError.validation("Output already exists. Pass --overwrite to replace it: \(config.outputURL.path)")
    }
}

do {
    switch try Arguments.parse(CommandLine.arguments) {
    case .help:
        print(Arguments.usage)
        exit(0)
    case .trackBoxesSelfTest:
        try TrackBoxesSelfTests.run()
        exit(0)
    case .run(let config):
        try run(config)
        exit(0)
    case .trackBoxes(let options):
        try runTrackBoxes(options)
        exit(0)
    }
} catch let error as AppError {
    FileHandle.standardError.write(Data("error: \(error.description)\n".utf8))
    exit(error.exitCode)
} catch {
    FileHandle.standardError.write(Data("error: \(error.appMessage)\n".utf8))
    exit(6)
}
