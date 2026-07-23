import AppKit
import SwiftUI

enum GifJotDesign {
    static let canvasIndigoNS = nsColor(103, 88, 232)
    static let recordingRedNS = nsColor(209, 61, 67)

    static let canvasIndigo = Color(nsColor: canvasIndigoNS)
    static let pressedIndigo = color(85, 70, 215)
    static let recordingRed = Color(nsColor: recordingRedNS)
    static let pressedRecordingRed = color(184, 47, 54)
    static let indigoTint = adaptiveColor(
        light: nsColor(238, 236, 255),
        dark: nsColor(50, 45, 91)
    )

    // Compatibility names used by the existing menu and settings surfaces.
    static let signal = canvasIndigo
    static let deepSignal = pressedIndigo
    static let pressedSignal = pressedIndigo

    static let opticalBody = adaptiveColor(
        light: nsColor(249, 249, 251),
        dark: nsColor(31, 31, 34)
    )
    static let vellum = adaptiveColor(
        light: nsColor(241, 241, 244),
        dark: nsColor(42, 42, 46)
    )
    static let shellHighlight = adaptiveColor(
        light: nsColor(255, 255, 255),
        dark: nsColor(50, 50, 54)
    )
    static let opticalHairline = adaptiveColor(
        light: nsColor(218, 218, 224),
        dark: nsColor(67, 67, 72)
    )
    static let mutedInk = adaptiveColor(
        light: nsColor(93, 93, 102),
        dark: nsColor(174, 174, 183)
    )
    static let hudSurface = adaptiveColor(
        light: nsColor(252, 252, 253),
        dark: nsColor(38, 38, 41)
    )
    static let hudControl = adaptiveColor(
        light: nsColor(242, 242, 245),
        dark: nsColor(53, 53, 57)
    )
    static let hudHairline = adaptiveColor(
        light: nsColor(215, 215, 221),
        dark: nsColor(74, 74, 80)
    )

    static let graphite = color(29, 29, 32)
    static let cameraBlack = color(29, 29, 32)
    static let warmChalk = color(250, 250, 252)
    static let mutedChalk = color(182, 182, 190)
    static let success = adaptiveColor(
        light: nsColor(46, 125, 76),
        dark: nsColor(90, 166, 111)
    )
    static let warning = adaptiveColor(
        light: nsColor(185, 109, 15),
        dark: nsColor(217, 144, 47)
    )

    // Compatibility aliases for the existing recording surfaces.
    static let carbon = cameraBlack
    static let softPaper = warmChalk

    static let panelWidth: CGFloat = 344
    static let controlRadius: CGFloat = 8
    static let surfaceRadius: CGFloat = 12
    static let panelRadius: CGFloat = 14
    static let shutterSize: CGFloat = 46

    static func actionFill(for colorScheme: ColorScheme) -> Color {
        canvasIndigo
    }

    static func actionForeground(for colorScheme: ColorScheme) -> Color {
        .white
    }

    private static func color(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(nsColor: nsColor(red, green, blue))
    }

    private static func nsColor(
        _ red: Int,
        _ green: Int,
        _ blue: Int
    ) -> NSColor {
        NSColor(
            srgbRed: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }

    private static func adaptiveColor(
        light: NSColor,
        dark: NSColor
    ) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? dark
                    : light
            }
        )
    }
}

struct CaptureFrameMark: View {
    let color: Color
    var isActive = false
    var lineWidth: CGFloat = 1.75

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let inset = lineWidth / 2
            let corner = min(size.width, size.height) * 0.34

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: inset, y: corner))
                    path.addLine(to: CGPoint(x: inset, y: inset))
                    path.addLine(to: CGPoint(x: corner, y: inset))

                    path.move(to: CGPoint(x: size.width - corner, y: inset))
                    path.addLine(to: CGPoint(x: size.width - inset, y: inset))
                    path.addLine(to: CGPoint(x: size.width - inset, y: corner))

                    path.move(to: CGPoint(x: size.width - inset, y: size.height - corner))
                    path.addLine(to: CGPoint(x: size.width - inset, y: size.height - inset))
                    path.addLine(to: CGPoint(x: size.width - corner, y: size.height - inset))

                    path.move(to: CGPoint(x: corner, y: size.height - inset))
                    path.addLine(to: CGPoint(x: inset, y: size.height - inset))
                    path.addLine(to: CGPoint(x: inset, y: size.height - corner))
                }
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .square,
                        lineJoin: .miter
                    )
                )

                if isActive {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(color)
                        .frame(
                            width: max(4, size.width * 0.22),
                            height: max(4, size.height * 0.22)
                        )
                }
            }
        }
    }
}

struct GifJotKeycap: View {
    let text: String
    var inverted = false

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(-0.2)
            .foregroundStyle(
                inverted
                    ? GifJotDesign.warmChalk.opacity(0.84)
                    : GifJotDesign.mutedInk
            )
            .padding(.horizontal, 7)
            .frame(height: 24)
            .background(
                inverted
                    ? Color.black.opacity(0.16)
                    : GifJotDesign.shellHighlight
            )
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(
                        inverted
                            ? GifJotDesign.warmChalk.opacity(0.18)
                            : GifJotDesign.opticalHairline
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
            )
    }
}

struct GifJotShutterRowButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                configuration.isPressed
                    ? GifJotDesign.shellHighlight
                    : Color.clear
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.surfaceRadius,
                    style: .continuous
                )
            )
            .opacity(isEnabled ? 1 : 0.48)
            .animation(
                .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.09),
                value: configuration.isPressed
            )
    }
}

struct GifJotPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(
                configuration.isPressed
                    ? GifJotDesign.pressedIndigo
                    : GifJotDesign.canvasIndigo
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(Color.white.opacity(0.12))
            }
            .opacity(isEnabled ? 1 : 0.48)
            .animation(
                .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.16),
                value: configuration.isPressed
            )
    }
}

struct GifJotSignalButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(GifJotDesign.warmChalk)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(
                configuration.isPressed
                    ? GifJotDesign.pressedRecordingRed
                    : GifJotDesign.recordingRed
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(Color.black.opacity(0.12))
            }
            .opacity(isEnabled ? 1 : 0.48)
    }
}

struct GifJotDarkQuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background(
                configuration.isPressed
                    ? GifJotDesign.indigoTint
                    : GifJotDesign.hudControl
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.hudHairline)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
            )
    }
}

struct GifJotInlineActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(
                GifJotDesign.shellHighlight
                    .opacity(configuration.isPressed ? 1 : 0)
            )
            .contentShape(Rectangle())
    }
}

struct GifJotQuietButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 11)
            .frame(minHeight: 32)
            .background(
                configuration.isPressed
                    ? GifJotDesign.shellHighlight
                    : GifJotDesign.vellum
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.controlRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.opticalHairline)
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
            .frame(width: 30, height: 30)
            .background(
                GifJotDesign.vellum.opacity(configuration.isPressed ? 1 : 0)
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
            .background(GifJotDesign.vellum)
            .overlay {
                RoundedRectangle(
                    cornerRadius: GifJotDesign.surfaceRadius,
                    style: .continuous
                )
                .stroke(GifJotDesign.opticalHairline)
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
