import CoreGraphics

struct CaptureRegion: Equatable, Sendable {
    let displayID: CGDirectDisplayID
    let sourceRect: CGRect
    let displayScale: CGFloat
}

enum RegionSelectionGeometry {
    static let minimumSelectionLength: CGFloat = 2

    static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    static func clampedAppKitRect(
        from start: CGPoint,
        to end: CGPoint,
        within bounds: CGRect
    ) -> CGRect? {
        let selection = normalizedRect(from: start, to: end)
            .intersection(bounds)

        guard !selection.isNull,
              selection.width >= minimumSelectionLength,
              selection.height >= minimumSelectionLength
        else {
            return nil
        }

        let minX = floor(selection.minX)
        let minY = floor(selection.minY)
        let maxX = ceil(selection.maxX)
        let maxY = ceil(selection.maxY)

        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        ).intersection(bounds)
    }

    static func sourceRect(
        fromLocalAppKitRect selection: CGRect,
        displaySize: CGSize
    ) -> CGRect? {
        let displayBounds = CGRect(origin: .zero, size: displaySize)
        let clamped = selection.standardized.intersection(displayBounds)

        guard !clamped.isNull,
              clamped.width >= minimumSelectionLength,
              clamped.height >= minimumSelectionLength
        else {
            return nil
        }

        return CGRect(
            x: clamped.minX,
            y: displaySize.height - clamped.maxY,
            width: clamped.width,
            height: clamped.height
        )
    }

    static func sourceRect(
        fromGlobalAppKitRect selection: CGRect,
        displayFrame: CGRect
    ) -> CGRect? {
        let clamped = selection.standardized.intersection(displayFrame)
        guard !clamped.isNull else { return nil }

        let local = clamped.offsetBy(
            dx: -displayFrame.minX,
            dy: -displayFrame.minY
        )

        return sourceRect(
            fromLocalAppKitRect: local,
            displaySize: displayFrame.size
        )
    }
}
