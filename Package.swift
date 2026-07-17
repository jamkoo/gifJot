// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "GifJotCore",
    products: [
        .library(name: "GifJotCore", targets: ["GifJotCore"]),
    ],
    targets: [
        .target(
            name: "GifJotCore",
            path: "apps/macos/GifJot",
            exclude: [
                "App",
                "Capture",
                "Export/FileClipboardWriter.swift",
                "Info.plist",
                "Recording/GIFEncoding.swift",
                "Recording/OutputDimensions.swift",
                "Recording/RecordingFramePipeline.swift",
                "Recording/TemporaryRecordingStore.swift",
                "Settings",
            ],
            sources: [
                "Export/GIFFileExporter.swift",
                "Export/RecentOutputStore.swift",
                "Recording/GIFFrameTiming.swift",
                "Recording/RecordingStateMachine.swift",
            ]
        ),
        .testTarget(
            name: "GifJotCoreTests",
            dependencies: ["GifJotCore"],
            path: "apps/macos/GifJotTests",
            exclude: [
                "ApplicationRelauncherTests.swift",
                "BoundedFrameAdmissionTests.swift",
                "CaptureDiagnosticAccumulatorTests.swift",
                "CapturePermissionServiceTests.swift",
                "ImageIOGIFEncoderTests.swift",
                "OutputDimensionsTests.swift",
                "RecordingHUDPlacementTests.swift",
                "RecordingStreamStateTests.swift",
                "RegionSelectionGeometryTests.swift",
                "SettingsStoreTests.swift",
            ],
            sources: [
                "GIFFileExporterTests.swift",
                "GIFFrameTimingTests.swift",
                "RecentOutputStoreTests.swift",
                "RecordingFilenameGeneratorTests.swift",
                "RecordingStateMachineTests.swift",
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
