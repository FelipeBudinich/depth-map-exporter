import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation

enum TrackColor: Int, CaseIterable {
    case red = 0
    case blue = 1
    case yellow = 2
    case green = 3

    var name: String {
        switch self {
        case .red: return "red"
        case .blue: return "blue"
        case .yellow: return "yellow"
        case .green: return "green"
        }
    }

    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        switch self {
        case .red:
            return (1.0, 0.05, 0.02, 1.0)
        case .blue:
            return (0.05, 0.35, 1.0, 1.0)
        case .yellow:
            return (1.0, 0.86, 0.05, 1.0)
        case .green:
            return (0.05, 0.78, 0.24, 1.0)
        }
    }
}

enum BoxSource: String {
    case seed
    case visionForward
    case visionBackward
    case reacquired
    case deadReckoned
    case corrected
    case missing
}

struct TrackedBox {
    let frameIndex: Int
    let timestamp: CMTime
    let trackID: Int
    let color: TrackColor
    let rect: CGRect
    let confidence: Float
    let source: BoxSource
    let isVisible: Bool
}

struct TrackBoxFrameDebug {
    let frameIndex: Int
    let timestamp: CMTime
    let trackID: Int
    let color: TrackColor
    let rect: CGRect?
    let confidence: Float
    let source: BoxSource
    let isVisible: Bool
    let velocity: CGVector
    let missingFrameCount: Int
    let rawVisionForwardRect: CGRect?
    let rawVisionBackwardRect: CGRect?
    let reacquireCandidate: CGRect?
    let rejectedReason: String?
}

final class ObjectTrack {
    let trackID: Int
    let color: TrackColor
    var forwardBoxes: [Int: TrackedBox] = [:]
    var backwardBoxes: [Int: TrackedBox] = [:]
    var correctedBoxes: [Int: TrackedBox] = [:]
    var lastReliableBox: TrackedBox?
    var recentReliableBoxes: [TrackedBox] = []
    var velocity = CGVector(dx: 0, dy: 0)
    var sizeVelocity = CGSize(width: 0, height: 0)
    var missingFrameCount = 0
    var velocityByFrame: [Int: CGVector] = [:]
    var missingCountByFrame: [Int: Int] = [:]
    var rawVisionForwardByFrame: [Int: CGRect] = [:]
    var rawVisionBackwardByFrame: [Int: CGRect] = [:]
    var reacquireCandidateByFrame: [Int: CGRect] = [:]
    var rejectedReasonByFrame: [Int: String] = [:]

    init(trackID: Int, color: TrackColor) {
        self.trackID = trackID
        self.color = color
    }

    func recordForward(_ box: TrackedBox, reliable: Bool) {
        forwardBoxes[box.frameIndex] = box
        correctedBoxes[box.frameIndex] = box
        if reliable {
            updateMotion(with: box)
        } else {
            recordFrameState(frameIndex: box.frameIndex)
        }
    }

    func recordBackward(_ box: TrackedBox) {
        backwardBoxes[box.frameIndex] = box
    }

    func recordCorrected(_ box: TrackedBox) {
        correctedBoxes[box.frameIndex] = box
    }

    func recordMissing(frameIndex: Int, timestamp: CMTime, reason: String) {
        let box = TrackedBox(
            frameIndex: frameIndex,
            timestamp: timestamp,
            trackID: trackID,
            color: color,
            rect: .null,
            confidence: 0,
            source: .missing,
            isVisible: false
        )
        rejectedReasonByFrame[frameIndex] = reason
        forwardBoxes[frameIndex] = box
        correctedBoxes[frameIndex] = box
        incrementMissing(frameIndex: frameIndex)
    }

    func reliableBox(at frameIndex: Int) -> TrackedBox? {
        if let box = forwardBoxes[frameIndex], box.isReliableObservation {
            return box
        }
        if let box = backwardBoxes[frameIndex], box.isReliableObservation {
            return box
        }
        return nil
    }

    func reliableFrameIndices() -> [Int] {
        let indices = Set(forwardBoxes.values.filter(\.isReliableObservation).map(\.frameIndex))
            .union(backwardBoxes.values.filter(\.isReliableObservation).map(\.frameIndex))
        return indices.sorted()
    }

    private func updateMotion(with box: TrackedBox) {
        if let previous = lastReliableBox {
            let deltaFrames = max(1, box.frameIndex - previous.frameIndex)
            velocity = CGVector(
                dx: (box.rect.midX - previous.rect.midX) / CGFloat(deltaFrames),
                dy: (box.rect.midY - previous.rect.midY) / CGFloat(deltaFrames)
            )
            sizeVelocity = CGSize(
                width: (box.rect.width - previous.rect.width) / CGFloat(deltaFrames),
                height: (box.rect.height - previous.rect.height) / CGFloat(deltaFrames)
            )
        }
        lastReliableBox = box
        recentReliableBoxes.append(box)
        if recentReliableBoxes.count > 5 {
            recentReliableBoxes.removeFirst(recentReliableBoxes.count - 5)
        }
        missingFrameCount = 0
        recordFrameState(frameIndex: box.frameIndex)
    }

    func incrementMissing(frameIndex: Int) {
        missingFrameCount += 1
        velocity.dx *= 0.95
        velocity.dy *= 0.95
        sizeVelocity.width *= 0.95
        sizeVelocity.height *= 0.95
        recordFrameState(frameIndex: frameIndex)
    }

    private func recordFrameState(frameIndex: Int) {
        velocityByFrame[frameIndex] = velocity
        missingCountByFrame[frameIndex] = missingFrameCount
    }
}

extension TrackedBox {
    var isReliableObservation: Bool {
        isVisible && (source == .seed || source == .visionForward || source == .visionBackward || source == .reacquired)
    }
}

struct VisionCoordinateMapper {
    let outputSize: CGSize

    func visionRect(fromPixelRect rect: CGRect) -> CGRect {
        let clamped = BoxGeometry.clampedToFrame(rect, frameSize: outputSize)
        return CGRect(
            x: clamped.minX / max(1, outputSize.width),
            y: 1 - (clamped.maxY / max(1, outputSize.height)),
            width: clamped.width / max(1, outputSize.width),
            height: clamped.height / max(1, outputSize.height)
        ).standardized
    }

    func pixelRect(fromVisionRect rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX * outputSize.width,
            y: (1 - rect.maxY) * outputSize.height,
            width: rect.width * outputSize.width,
            height: rect.height * outputSize.height
        ).standardized
    }
}

enum BoxGeometry {
    static func clampedToFrame(_ rect: CGRect, frameSize: CGSize) -> CGRect {
        guard rect.isFiniteRect else {
            return .null
        }
        let frame = CGRect(origin: .zero, size: frameSize)
        let intersection = rect.standardized.intersection(frame)
        return intersection.isNull ? .null : intersection.standardized
    }

    static func isValidBox(_ rect: CGRect, frameSize: CGSize) -> Bool {
        guard rect.isFiniteRect, rect.width > 1, rect.height > 1 else {
            return false
        }
        let frameArea = max(1, frameSize.width * frameSize.height)
        let area = rect.width * rect.height
        guard area >= max(16, frameArea * 0.00005), area <= frameArea * 0.95 else {
            return false
        }
        let clamped = clampedToFrame(rect, frameSize: frameSize)
        guard !clamped.isNull else {
            return false
        }
        return clamped.width * clamped.height >= area * 0.5
    }

    static func boxIoU(_ lhs: CGRect, _ rhs: CGRect) -> Double {
        guard lhs.isFiniteRect, rhs.isFiniteRect else {
            return 0
        }
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else {
            return 0
        }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = lhs.width * lhs.height + rhs.width * rhs.height - intersectionArea
        return unionArea > 0 ? Double(intersectionArea / unionArea) : 0
    }

    static func centroidDistance(_ lhs: CGRect, _ rhs: CGRect, frameSize: CGSize) -> Double {
        let diagonal = max(1, hypot(frameSize.width, frameSize.height))
        return Double(hypot(lhs.midX - rhs.midX, lhs.midY - rhs.midY) / diagonal)
    }

    static func sizeSimilarity(_ lhs: CGRect, _ rhs: CGRect) -> Double {
        guard lhs.width > 0, lhs.height > 0, rhs.width > 0, rhs.height > 0 else {
            return 0
        }
        let widthRatio = min(lhs.width, rhs.width) / max(lhs.width, rhs.width)
        let heightRatio = min(lhs.height, rhs.height) / max(lhs.height, rhs.height)
        return Double(widthRatio * heightRatio)
    }

    static func interpolate(_ lhs: CGRect, _ rhs: CGRect, t: CGFloat) -> CGRect {
        let clampedT = max(0, min(1, t))
        return CGRect(
            x: lhs.origin.x + (rhs.origin.x - lhs.origin.x) * clampedT,
            y: lhs.origin.y + (rhs.origin.y - lhs.origin.y) * clampedT,
            width: lhs.width + (rhs.width - lhs.width) * clampedT,
            height: lhs.height + (rhs.height - lhs.height) * clampedT
        )
    }
}

enum DeadReckoner {
    static func box(
        for track: ObjectTrack,
        frameIndex: Int,
        timestamp: CMTime,
        frameSize: CGSize,
        maxDeadReckonFrames: Int
    ) -> TrackedBox {
        track.incrementMissing(frameIndex: frameIndex)
        guard track.missingFrameCount <= maxDeadReckonFrames,
              let previous = track.forwardBoxes[frameIndex - 1] ?? track.lastReliableBox,
              previous.isVisible,
              previous.rect.isFiniteRect else {
            return missing(track: track, frameIndex: frameIndex, timestamp: timestamp)
        }

        let sizeDeltaLimit: CGFloat = 12
        let widthDelta = max(-sizeDeltaLimit, min(sizeDeltaLimit, track.sizeVelocity.width))
        let heightDelta = max(-sizeDeltaLimit, min(sizeDeltaLimit, track.sizeVelocity.height))
        let predicted = BoxGeometry.clampedToFrame(
            CGRect(
                x: previous.rect.origin.x + track.velocity.dx,
                y: previous.rect.origin.y + track.velocity.dy,
                width: max(2, previous.rect.width + widthDelta),
                height: max(2, previous.rect.height + heightDelta)
            ),
            frameSize: frameSize
        )
        guard BoxGeometry.isValidBox(predicted, frameSize: frameSize) else {
            return missing(track: track, frameIndex: frameIndex, timestamp: timestamp)
        }
        return TrackedBox(
            frameIndex: frameIndex,
            timestamp: timestamp,
            trackID: track.trackID,
            color: track.color,
            rect: predicted,
            confidence: max(0, previous.confidence * 0.85),
            source: .deadReckoned,
            isVisible: true
        )
    }

    static func missing(track: ObjectTrack, frameIndex: Int, timestamp: CMTime) -> TrackedBox {
        TrackedBox(
            frameIndex: frameIndex,
            timestamp: timestamp,
            trackID: track.trackID,
            color: track.color,
            rect: .null,
            confidence: 0,
            source: .missing,
            isVisible: false
        )
    }
}

enum BackwardCorrector {
    static func correctedTimeline(
        track: ObjectTrack,
        timestamps: [CMTime],
        frameSize: CGSize,
        window: Int,
        maxDeadReckonFrames: Int
    ) -> [Int: TrackedBox] {
        var output: [Int: TrackedBox] = [:]
        let reliableIndices = track.reliableFrameIndices()

        for frameIndex in timestamps.indices {
            if let reliable = track.reliableBox(at: frameIndex) {
                output[frameIndex] = reliable
                continue
            }

            let previousIndex = reliableIndices.last { $0 < frameIndex && frameIndex - $0 <= window }
            let nextIndex = reliableIndices.first { $0 > frameIndex && $0 - frameIndex <= window }
            if let previousIndex,
               let nextIndex,
               let previous = track.reliableBox(at: previousIndex),
               let next = track.reliableBox(at: nextIndex),
               nextIndex > previousIndex {
                let t = CGFloat(frameIndex - previousIndex) / CGFloat(nextIndex - previousIndex)
                let rect = BoxGeometry.clampedToFrame(BoxGeometry.interpolate(previous.rect, next.rect, t: t), frameSize: frameSize)
                if BoxGeometry.isValidBox(rect, frameSize: frameSize) {
                    output[frameIndex] = TrackedBox(
                        frameIndex: frameIndex,
                        timestamp: timestamps[frameIndex],
                        trackID: track.trackID,
                        color: track.color,
                        rect: rect,
                        confidence: min(previous.confidence, next.confidence) * 0.85,
                        source: .corrected,
                        isVisible: true
                    )
                    continue
                }
            }

            if let forward = track.forwardBoxes[frameIndex], forward.source == .deadReckoned, forward.isVisible {
                output[frameIndex] = forward
            } else if let nextIndex,
                      nextIndex - frameIndex <= maxDeadReckonFrames,
                      let next = track.reliableBox(at: nextIndex) {
                output[frameIndex] = TrackedBox(
                    frameIndex: frameIndex,
                    timestamp: timestamps[frameIndex],
                    trackID: track.trackID,
                    color: track.color,
                    rect: next.rect,
                    confidence: next.confidence * 0.5,
                    source: .corrected,
                    isVisible: true
                )
            } else {
                output[frameIndex] = DeadReckoner.missing(track: track, frameIndex: frameIndex, timestamp: timestamps[frameIndex])
            }
        }
        return output
    }
}

extension CGRect {
    var isFiniteRect: Bool {
        origin.x.isFinite &&
            origin.y.isFinite &&
            size.width.isFinite &&
            size.height.isFinite &&
            !isNull &&
            !isInfinite
    }
}
