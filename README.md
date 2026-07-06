# depth-exporter

`depth-exporter` is a native macOS command-line tool for converting an H.264 MP4 video into a grayscale H.264 MP4 visual depth-map video. It reads frames with AVFoundation, runs a local Core ML monocular depth model, and writes a new MP4 without image sequences, FFmpeg, Python, Node.js, Electron, ONNX Runtime, or OpenCV in the main path.

## Requirements

- macOS 13 or newer
- Apple Silicon Mac
- Xcode command line tools
- A local Core ML depth model (`.mlpackage`, `.mlmodel`, or `.mlmodelc`)

Recommended model: Depth Anything V2 Small F16 Core ML package.

## Build

```sh
swift build -c release --arch arm64
```

## Run

```sh
.build/arm64-apple-macosx/release/depth-exporter \
  --input input.mp4 \
  --output output-depth.mp4 \
  --model DepthAnythingV2SmallF16.mlpackage \
  --model-input auto \
  --model-short-side 518 \
  --model-size-multiple 14 \
  --overwrite
```

## Options

```sh
depth-exporter \
  --input input.mp4 \
  --output output-depth.mp4 \
  --model DepthAnythingV2SmallF16.mlpackage \
  --compute all \
  --format grayscale \
  --normalize global \
  --model-input auto \
  --model-resize stretch \
  --model-short-side 518 \
  --model-size-multiple 14 \
  --output-max-side 1920 \
  --bitrate 12000000 \
  --sample-step 30 \
  --include-audio \
  --stack-vertical \
  --progress-json \
  --overwrite
```

- `--compute all|cpuAndGPU|cpuAndNeuralEngine|cpuOnly` controls Core ML compute units. Default: `all`.
- `--format grayscale|inverse-grayscale` controls display polarity. Default: `grayscale`.
- `--normalize global|ema|per-frame` controls depth range stabilization. Default: `global`.
- `--model-input auto|WIDTHxHEIGHT` selects the Core ML inference size. Default: `auto`.
- `--model-resize stretch|letterbox` controls how frames are resized into the model input size. Default: `stretch`.
- `--letterbox` is a shortcut for `--model-resize letterbox`.
- `--model-short-side <int>` sets the inference short side for flexible or vague model inputs. Default: `518`.
- `--model-size-multiple <int>` rounds flexible or vague inference dimensions to a multiple. Default: `14`.
- `--output-max-side <int>` caps the output long side while preserving aspect ratio. Output dimensions are even for H.264. Default: `1920`.
- `--bitrate <int>` sets the H.264 average bitrate. Default: `12000000`.
- `--sample-step <int>` controls the sampling interval for global normalization. Default: `30`.
- `--include-audio` copies the first source audio track into the output. Default: disabled.
- `--stack-vertical` exports a comparison video with the source panel above the depth panel. Default: disabled.
- `--progress-json` emits JSONL progress events to stdout. Human logs are written to stderr.
- `--dry-run` validates paths, video metadata, and model metadata without exporting.

## V2 Model Input Scaling

`--model-input`, `--model-short-side`, and `--model-size-multiple` control the Core ML inference resolution. `--model-resize` controls how decoded video frames are fitted into that inference size. `--output-max-side` controls only the final exported MP4 resolution. Keeping these separate avoids accidentally running expensive full-resolution video frames through the depth model.

With `--model-input auto`, `depth-exporter` inspects the Core ML image input constraints once before export and uses the same resolved size for dry-run, global normalization sampling, and final frame processing.

- Fixed-shape image inputs use the model-required size. By default, frames are stretched non-proportionally if the source aspect ratio differs from the model aspect ratio.
- Pass `--model-resize letterbox` or `--letterbox` to preserve source aspect ratio with black aspect-fit letterboxing.
- Enumerated image inputs choose the allowed size closest to the source aspect ratio while staying near the requested short side.
- Flexible or vague image inputs use Depth Anything V2-style sizing by default: short side `518`, dimensions rounded to a multiple of `14`, and source aspect ratio preserved.

Examples:

- `1920x1080` source, flexible model: inference around `924x518`, output up to `1920x1080`.
- `1080x1920` source, flexible model: inference around `518x924`, output up to `1080x1920`.
- `3840x2160` source, flexible model: inference around `924x518`, output reduced only if `--output-max-side` is below `3840`.

## Notes

The output MP4 is intended for visual depth-map playback, not lossless depth data. Silent depth-only video is the default. Pass `--include-audio` to include the first source audio track; if the input has no audio track, the export continues silently and prints a warning.

Pass `--stack-vertical` to export a test video with the display-oriented source frame on top and the rendered depth map on the bottom. `--output-max-side` controls each panel size, so the final stacked file is `panelWidth x panelHeight*2`. Stacked mode uses original audio only when `--include-audio` is also set.

The default bitrate is unchanged for stacked exports. Because stacked mode doubles the panel height, raise `--bitrate` manually if the comparison video needs more detail.

Global normalization is the recommended default because it samples the video first and then renders all frames with a stable range. EMA normalization is single-pass and smooths the range over time. Per-frame normalization is useful for debugging but may flicker because every frame gets its own range.

Compiled Core ML models are cached under:

```text
~/Library/Caches/depth-exporter/
```

Some Core ML packages expose a strict enumerated image input size. When that happens, `depth-exporter` uses the model-required input size and reports that choice on stderr; flexible models use the aspect-derived `--model-short-side` and `--model-size-multiple` settings. If the source and model aspect ratios differ, default preprocessing stretches to the model input size unless letterboxing is explicitly enabled.

## Troubleshooting

- `Model does not expose an image input`: use a Core ML model that accepts an image input.
- `No usable depth output was produced`: the model must output either an image buffer or an `MLMultiArray`.
- `Invalid --model-input`: use `auto` or a positive `WIDTHxHEIGHT` value such as `924x518`.
- `--model-input is incompatible`: the explicit size is outside the model's fixed, enumerated, or ranged input constraints.
- `Output already exists`: pass `--overwrite` or choose a different output path.
- `Input does not contain a video track`: verify that the input is a valid local MP4 video.
- Model compilation issues: remove the cached model under `~/Library/Caches/depth-exporter/` and rerun.

## V3/V4 Electron GUI

The optional GUI in `electron-ui/` is a thin macOS Electron wrapper around the Swift CLI. The Swift executable remains the only video/depth processing engine: Electron handles dialogs, local HTML, job state, process spawning, progress display, cancellation, preview, and Reveal in Finder.

The renderer uses plain HTML, locally compiled Tailwind CSS, local htmx, and a small vanilla `app.js` for Server-Sent Events progress updates. It does not use React, Vue, Svelte, Angular, JSX, WebCodecs, browser ML, FFmpeg, Python, ONNX Runtime, or OpenCV.

Development:

```sh
cd electron-ui
npm install
npm run dev
```

Useful checks:

```sh
npm run build:css
npm run typecheck
npm run package:mac
```

CLI path resolution in development:

- Set `DEPTH_EXPORTER_PATH=/absolute/path/to/depth-exporter`, or
- build the Swift CLI at `.build/arm64-apple-macosx/release/depth-exporter`, or
- place a binary at `electron-ui/resources/bin/depth-exporter`.

For packaged builds, `electron-builder` puts resources outside ASAR:

- CLI: `process.resourcesPath/bin/depth-exporter`
- Bundled model: `process.resourcesPath/models/DepthAnythingV2SmallF16.mlpackage`

To bundle a default model, place it at:

```text
electron-ui/resources/models/DepthAnythingV2SmallF16.mlpackage
```

The GUI pre-fills the model path when that bundled model exists, but users can choose another local `.mlpackage`, `.mlmodel`, or `.mlmodelc`.

The GUI exposes unchecked controls for `Include original audio` and `Export stacked test video`. By default it still exports a silent depth-only MP4. When enabled, those controls pass `--include-audio` and `--stack-vertical` directly to the Swift CLI. Suggested output names use `-depth.mp4`, `-depth-audio.mp4`, `-depth-test.mp4`, or `-depth-test-audio.mp4` based on the selected mode.

Model inference size is controlled separately from exported MP4 size by the V2 CLI settings: `--model-input`, `--model-short-side`, `--model-size-multiple`, and `--output-max-side`. In stacked GUI exports, `--output-max-side` controls each panel size; the same bitrate field is used, so raise it manually for high-detail comparison videos.
