import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum TemporaryRecordingStoreError: Error, LocalizedError, Sendable {
    case sessionNotStarted
    case couldNotCreateFrameDestination
    case couldNotWriteFrame

    var errorDescription: String? {
        switch self {
        case .sessionNotStarted:
            "The temporary recording session was not started."
        case .couldNotCreateFrameDestination:
            "GifJot could not create temporary frame storage."
        case .couldNotWriteFrame:
            "GifJot could not write a temporary recording frame."
        }
    }
}

enum FrameStorageOutcome: Equatable, Sendable {
    case stored
    case duplicate
    case capacityReached
}

private struct ExactFrameSnapshot {
    let width: Int
    let height: Int
    let bitsPerComponent: Int
    let bitsPerPixel: Int
    let bytesPerRow: Int
    let bitmapInfo: UInt32
    let bytes: Data
    let digest: Int

    init?(image: CGImage) {
        guard let providerData = image.dataProvider?.data else { return nil }

        let bytes = providerData as Data
        width = image.width
        height = image.height
        bitsPerComponent = image.bitsPerComponent
        bitsPerPixel = image.bitsPerPixel
        bytesPerRow = image.bytesPerRow
        bitmapInfo = image.bitmapInfo.rawValue
        self.bytes = bytes
        digest = bytes.hashValue
    }

    func isIdentical(to other: ExactFrameSnapshot) -> Bool {
        width == other.width
            && height == other.height
            && bitsPerComponent == other.bitsPerComponent
            && bitsPerPixel == other.bitsPerPixel
            && bytesPerRow == other.bytesPerRow
            && bitmapInfo == other.bitmapInfo
            && digest == other.digest
            && bytes == other.bytes
    }
}

final class TemporaryRecordingStore {
    static let directoryName = "GifJot"

    private let fileManager: FileManager
    private let baseDirectory: URL
    private let maximumFrameCount: Int

    private(set) var sessionDirectory: URL?
    private(set) var frames: [StoredCaptureFrame] = []
    private(set) var duplicateFrameCount = 0
    private var lastFrameSnapshot: ExactFrameSnapshot?

    init(
        baseDirectory: URL? = nil,
        maximumFrameCount: Int = 3_600,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.maximumFrameCount = max(1, maximumFrameCount)
        self.baseDirectory = baseDirectory
            ?? fileManager.temporaryDirectory.appendingPathComponent(
                Self.directoryName,
                isDirectory: true
            )
    }

    func beginSession() throws {
        cleanup()

        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
        let sessionDirectory = baseDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try fileManager.createDirectory(
            at: sessionDirectory,
            withIntermediateDirectories: false
        )

        self.sessionDirectory = sessionDirectory
        frames = []
        duplicateFrameCount = 0
        lastFrameSnapshot = nil
    }

    func append(
        image: CGImage,
        presentationTime: TimeInterval
    ) throws -> FrameStorageOutcome {
        guard let sessionDirectory else {
            throw TemporaryRecordingStoreError.sessionNotStarted
        }

        let snapshot = ExactFrameSnapshot(image: image)
        if let snapshot,
           let lastFrameSnapshot,
           snapshot.isIdentical(to: lastFrameSnapshot)
        {
            duplicateFrameCount += 1
            return .duplicate
        }

        guard frames.count < maximumFrameCount else {
            lastFrameSnapshot = nil
            return .capacityReached
        }

        let fileURL = sessionDirectory.appendingPathComponent(
            String(format: "%06d.png", frames.count)
        )
        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw TemporaryRecordingStoreError.couldNotCreateFrameDestination
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            try? fileManager.removeItem(at: fileURL)
            throw TemporaryRecordingStoreError.couldNotWriteFrame
        }

        frames.append(
            StoredCaptureFrame(
                fileURL: fileURL,
                presentationTime: presentationTime
            )
        )
        lastFrameSnapshot = snapshot
        return .stored
    }

    func cleanup() {
        let directory = sessionDirectory
        sessionDirectory = nil
        frames = []
        duplicateFrameCount = 0
        lastFrameSnapshot = nil

        if let directory {
            try? fileManager.removeItem(at: directory)
        }
    }

    static func removeAbandonedSessions(
        baseDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let directory = baseDirectory
            ?? fileManager.temporaryDirectory.appendingPathComponent(
                directoryName,
                isDirectory: true
            )
        try? fileManager.removeItem(at: directory)
    }
}
