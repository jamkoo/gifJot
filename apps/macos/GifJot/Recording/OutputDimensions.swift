import CoreGraphics
import Foundation

struct OutputDimensions: Equatable, Sendable {
    let width: Int
    let height: Int
}

enum OutputDimensionsCalculator {
    static func calculate(
        sourceSizeInPoints: CGSize,
        displayScale: CGFloat,
        maximumWidth: Int?
    ) -> OutputDimensions {
        let nativeWidth = max(
            1,
            Int((sourceSizeInPoints.width * max(displayScale, 1)).rounded())
        )
        let nativeHeight = max(
            1,
            Int((sourceSizeInPoints.height * max(displayScale, 1)).rounded())
        )

        guard let maximumWidth, nativeWidth > maximumWidth else {
            return OutputDimensions(width: nativeWidth, height: nativeHeight)
        }

        let scale = Double(maximumWidth) / Double(nativeWidth)
        return OutputDimensions(
            width: max(1, maximumWidth),
            height: max(1, Int((Double(nativeHeight) * scale).rounded()))
        )
    }
}
