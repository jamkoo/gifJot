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

final class TemporaryRecordingStore {
    static let directoryName = "GifJot"

    private let fileManager: FileManager
    private let baseDirectory: URL
    private let maximumFrameCount: Int

    private(set) var sessionDirectory: URL?
    private(set) var frames: [StoredCaptureFrame] = []

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
    }

    @discardableResult
    func append(
        image: CGImage,
        presentationTime: TimeInterval
    ) throws -> Bool {
        guard frames.count < maximumFrameCount else { return false }
        guard let sessionDirectory else {
            throw TemporaryRecordingStoreError.sessionNotStarted
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
        return true
    }

    func cleanup() {
        let directory = sessionDirectory
        sessionDirectory = nil
        frames = []

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
