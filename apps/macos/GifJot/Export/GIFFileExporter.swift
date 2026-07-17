import Foundation

struct GIFExportPlan: Equatable, Sendable {
    let workingURL: URL
    let finalURL: URL
}

enum GIFFileExporterError: Error, LocalizedError, Sendable {
    case downloadsDirectoryUnavailable
    case destinationAlreadyExists

    var errorDescription: String? {
        switch self {
        case .downloadsDirectoryUnavailable:
            "GifJot could not find the Downloads folder."
        case .destinationAlreadyExists:
            "A file appeared at the selected GIF destination. Please try again."
        }
    }
}

enum RecordingFilenameGenerator {
    static func baseName(
        for date: Date,
        calendar: Calendar = .current
    ) -> String {
        let parts = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        return String(
            format: "GifJot %04d-%02d-%02d at %02d.%02d.%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0,
            parts.hour ?? 0,
            parts.minute ?? 0,
            parts.second ?? 0
        )
    }

    static func nextAvailableURL(
        in directory: URL,
        date: Date,
        calendar: Calendar = .current,
        fileExists: (String) -> Bool
    ) -> URL {
        let baseName = baseName(for: date, calendar: calendar)
        var suffix = 1

        while true {
            let suffixText = suffix == 1 ? "" : "-\(suffix)"
            let filename = "\(baseName)\(suffixText).gif"
            let candidate = directory.appendingPathComponent(filename)
            if !fileExists(candidate.path) {
                return candidate
            }
            suffix += 1
        }
    }
}

final class GIFFileExporter {
    private static let workingFilenamePrefix = ".gifjot-"
    private static let workingFilenameSuffix = ".tmp"

    private let fileManager: FileManager
    private let destinationDirectory: URL

    init(
        destinationDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager

        if let destinationDirectory {
            self.destinationDirectory = destinationDirectory
        } else {
            self.destinationDirectory = try Self.defaultDestinationDirectory(
                fileManager: fileManager
            )
        }
    }

    func prepare(date: Date = Date()) throws -> GIFExportPlan {
        try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true
        )

        let finalURL = RecordingFilenameGenerator.nextAvailableURL(
            in: destinationDirectory,
            date: date,
            fileExists: fileManager.fileExists(atPath:)
        )
        let workingURL = destinationDirectory.appendingPathComponent(
            "\(Self.workingFilenamePrefix)\(UUID().uuidString)\(Self.workingFilenameSuffix)"
        )
        return GIFExportPlan(workingURL: workingURL, finalURL: finalURL)
    }

    func commit(_ plan: GIFExportPlan) throws -> URL {
        guard !fileManager.fileExists(atPath: plan.finalURL.path) else {
            throw GIFFileExporterError.destinationAlreadyExists
        }
        try fileManager.moveItem(at: plan.workingURL, to: plan.finalURL)
        return plan.finalURL
    }

    func discard(_ plan: GIFExportPlan) {
        try? fileManager.removeItem(at: plan.workingURL)
    }

    static func removeAbandonedWorkingFiles(
        destinationDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let directory: URL
        if let destinationDirectory {
            directory = destinationDirectory
        } else {
            guard let defaultDirectory = try? defaultDestinationDirectory(
                fileManager: fileManager
            ) else {
                return
            }
            directory = defaultDirectory
        }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for url in contents where isWorkingFile(url) {
            try? fileManager.removeItem(at: url)
        }
    }

    private static func defaultDestinationDirectory(
        fileManager: FileManager
    ) throws -> URL {
        guard let downloads = fileManager.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first else {
            throw GIFFileExporterError.downloadsDirectoryUnavailable
        }
        return downloads.appendingPathComponent("GifJot", isDirectory: true)
    }

    private static func isWorkingFile(_ url: URL) -> Bool {
        let filename = url.lastPathComponent
        return filename.hasPrefix(workingFilenamePrefix)
            && filename.hasSuffix(workingFilenameSuffix)
    }
}
