import Foundation

struct StoredCaptureFrame: Equatable, Sendable {
    let fileURL: URL
    let presentationTime: TimeInterval
}

struct GIFFrame: Equatable, Sendable {
    let fileURL: URL
    let delay: TimeInterval
}

enum GIFFrameTiming {
    static let minimumDelay: TimeInterval = 0.02
    static let maximumDelay: TimeInterval = 120

    static func makeFrames(
        from storedFrames: [StoredCaptureFrame],
        defaultDelay: TimeInterval,
        endingPresentationTime: TimeInterval? = nil
    ) -> [GIFFrame] {
        guard !storedFrames.isEmpty else { return [] }

        let fallback = clamped(defaultDelay)
        return storedFrames.enumerated().map { index, frame in
            let delay: TimeInterval
            if storedFrames.indices.contains(index + 1) {
                let measured = storedFrames[index + 1].presentationTime
                    - frame.presentationTime
                delay = measured.isFinite && measured > 0
                    ? clamped(measured)
                    : fallback
            } else {
                if let endingPresentationTime {
                    let measured = endingPresentationTime
                        - frame.presentationTime
                    delay = measured.isFinite && measured > 0
                        ? clamped(measured)
                        : fallback
                } else {
                    delay = fallback
                }
            }

            return GIFFrame(fileURL: frame.fileURL, delay: delay)
        }
    }

    private static func clamped(_ delay: TimeInterval) -> TimeInterval {
        min(max(delay, minimumDelay), maximumDelay)
    }
}
