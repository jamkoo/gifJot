import AppKit
import SwiftUI

enum GifJotDesign {
    static let signal = Color(
        red: 217.0 / 255.0,
        green: 74.0 / 255.0,
        blue: 54.0 / 255.0
    )
    static let deepSignal = Color(
        red: 185.0 / 255.0,
        green: 54.0 / 255.0,
        blue: 39.0 / 255.0
    )
    static let pressedSignal = Color(
        red: 148.0 / 255.0,
        green: 45.0 / 255.0,
        blue: 34.0 / 255.0
    )
    static let carbon = Color(
        red: 34.0 / 255.0,
        green: 34.0 / 255.0,
        blue: 32.0 / 255.0
    )
    static let softPaper = Color(
        red: 251.0 / 255.0,
        green: 250.0 / 255.0,
        blue: 247.0 / 255.0
    )

    static let panelWidth: CGFloat = 320
    static let controlRadius: CGFloat = 6
    static let surfaceRadius: CGFloat = 9
    static let panelRadius: CGFloat = 12
}

struct GifJotPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(GifJotDesign.softPaper)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .background(
                configuration.isPressed
                    ? GifJotDesign.pressedSignal
                    : GifJotDesign.deepSignal
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
            .opacity(isEnabled ? 1 : 0.48)
            .animation(
                .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.16),
                value: configuration.isPressed
            )
    }
}

struct GifJotQuietButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .frame(minHeight: 30)
            .background(
                Color(nsColor: configuration.isPressed
                    ? .selectedControlColor
                    : .controlBackgroundColor)
                    .opacity(configuration.isPressed ? 0.28 : 1)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(Color(nsColor: .separatorColor).opacity(0.72))
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
            .opacity(isEnabled ? 1 : 0.48)
    }
}

struct GifJotIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(
                Color(nsColor: .controlBackgroundColor)
                    .opacity(configuration.isPressed ? 0.84 : 0)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
    }
}

private struct GifJotGroupSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.surfaceRadius,
                    style: .continuous
                )
                .stroke(Color(nsColor: .separatorColor).opacity(0.68))
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.surfaceRadius,
                    style: .continuous
                )
            )
    }
}

extension View {
    func gifJotGroupSurface() -> some View {
        modifier(GifJotGroupSurface())
    }
}
