import CoreGraphics

enum CaptureFramePreset: CaseIterable, Identifiable, Hashable, Sendable {
    case fullScreen
    case widescreen
    case standard
    case square

    var id: Self { self }

    var displayName: String {
        switch self {
        case .fullScreen:
            "Full Screen"
        case .widescreen:
            "16:9"
        case .standard:
            "4:3"
        case .square:
            "1:1"
        }
    }

    var aspectRatio: CGFloat? {
        switch self {
        case .fullScreen:
            nil
        case .widescreen:
            16 / 9
        case .standard:
            4 / 3
        case .square:
            1
        }
    }
}

struct CaptureRegion: Equatable, Sendable {
    let displayID: CGDirectDisplayID
    let sourceRect: CGRect
    let displayScale: CGFloat
}

enum RegionSelectionResizeHandle: Equatable, Sendable {
    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest

    var movesMinimumX: Bool {
        self == .west || self == .northWest || self == .southWest
    }

    var movesMaximumX: Bool {
        self == .east || self == .northEast || self == .southEast
    }

    var movesMinimumY: Bool {
        self == .south || self == .southEast || self == .southWest
    }

    var movesMaximumY: Bool {
        self == .north || self == .northEast || self == .northWest
    }
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

    static func movedSourceRect(
        _ sourceRect: CGRect,
        byAppKitDelta delta: CGPoint,
        within displaySize: CGSize
    ) -> CGRect {
        let maximumX = max(0, displaySize.width - sourceRect.width)
        let maximumY = max(0, displaySize.height - sourceRect.height)
        let origin = CGPoint(
            x: min(max(sourceRect.minX + delta.x, 0), maximumX),
            y: min(max(sourceRect.minY - delta.y, 0), maximumY)
        )

        return CGRect(origin: origin, size: sourceRect.size)
    }

    static func resizedSourceRect(
        _ sourceRect: CGRect,
        byAppKitDelta delta: CGPoint,
        handle: RegionSelectionResizeHandle,
        within displaySize: CGSize
    ) -> CGRect {
        let minimumLength = Self.minimumSelectionLength
        var appKitRect = CGRect(
            x: sourceRect.minX,
            y: displaySize.height - sourceRect.maxY,
            width: sourceRect.width,
            height: sourceRect.height
        )

        if handle.movesMinimumX {
            let maximumX = appKitRect.maxX
            let minimumX = min(
                max(appKitRect.minX + delta.x, 0),
                maximumX - minimumLength
            )
            appKitRect.origin.x = minimumX
            appKitRect.size.width = maximumX - minimumX
        }
        if handle.movesMaximumX {
            appKitRect.size.width = min(
                max(appKitRect.width + delta.x, minimumLength),
                displaySize.width - appKitRect.minX
            )
        }
        if handle.movesMinimumY {
            let maximumY = appKitRect.maxY
            let minimumY = min(
                max(appKitRect.minY + delta.y, 0),
                maximumY - minimumLength
            )
            appKitRect.origin.y = minimumY
            appKitRect.size.height = maximumY - minimumY
        }
        if handle.movesMaximumY {
            appKitRect.size.height = min(
                max(appKitRect.height + delta.y, minimumLength),
                displaySize.height - appKitRect.minY
            )
        }

        return Self.sourceRect(
            fromLocalAppKitRect: appKitRect,
            displaySize: displaySize
        ) ?? sourceRect
    }

    static func sourceRect(
        applying preset: CaptureFramePreset,
        to sourceRect: CGRect,
        within displaySize: CGSize
    ) -> CGRect {
        guard let aspectRatio = preset.aspectRatio else {
            return CGRect(origin: .zero, size: displaySize)
        }

        let currentRatio = sourceRect.width / sourceRect.height
        let size: CGSize
        if currentRatio > aspectRatio {
            size = CGSize(
                width: sourceRect.height * aspectRatio,
                height: sourceRect.height
            )
        } else {
            size = CGSize(
                width: sourceRect.width,
                height: sourceRect.width / aspectRatio
            )
        }

        let maximumX = max(0, displaySize.width - size.width)
        let maximumY = max(0, displaySize.height - size.height)
        let origin = CGPoint(
            x: min(max(sourceRect.midX - size.width / 2, 0), maximumX),
            y: min(max(sourceRect.midY - size.height / 2, 0), maximumY)
        )
        return CGRect(origin: origin, size: size)
    }
}
