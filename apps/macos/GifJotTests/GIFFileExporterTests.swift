import Foundation
import XCTest
#if canImport(GifJotCore)
@testable import GifJotCore
#else
@testable import GifJot
#endif

final class GIFFileExporterTests: XCTestCase {
    func testDefaultDestinationIsVisibleFolderInHomeDirectory() {
        XCTAssertEqual(
            GIFFileExporter.defaultDestinationDirectory(),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("GifJot", isDirectory: true)
                .standardizedFileURL
        )
    }

    func testCommitsWorkingFileWithoutOverwritingCollision() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotExporterTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let exporter = try GIFFileExporter(destinationDirectory: root)
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let firstPlan = try exporter.prepare(date: date)
        try Data("first".utf8).write(to: firstPlan.workingURL)
        let firstURL = try exporter.commit(firstPlan)

        let secondPlan = try exporter.prepare(date: date)
        try Data("second".utf8).write(to: secondPlan.workingURL)
        let secondURL = try exporter.commit(secondPlan)

        XCTAssertNotEqual(firstURL, secondURL)
        XCTAssertTrue(secondURL.deletingPathExtension().lastPathComponent.hasSuffix("-2"))
        XCTAssertEqual(try Data(contentsOf: firstURL), Data("first".utf8))
        XCTAssertEqual(try Data(contentsOf: secondURL), Data("second".utf8))
    }

    func testDiscardRemovesPartialWorkingFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotExporterTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let exporter = try GIFFileExporter(destinationDirectory: root)
        let plan = try exporter.prepare()
        try Data("partial".utf8).write(to: plan.workingURL)

        exporter.discard(plan)

        XCTAssertFalse(FileManager.default.fileExists(atPath: plan.workingURL.path))
    }

    func testAbandonedWorkingFileCleanupLeavesUserFilesAlone() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotExporterTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let abandoned = root.appendingPathComponent(".gifjot-abandoned.tmp")
        let userGIF = root.appendingPathComponent("keep.gif")
        let unrelatedTemporaryFile = root.appendingPathComponent("other.tmp")
        try Data("partial".utf8).write(to: abandoned)
        try Data("gif".utf8).write(to: userGIF)
        try Data("temporary".utf8).write(to: unrelatedTemporaryFile)

        GIFFileExporter.removeAbandonedWorkingFiles(
            destinationDirectory: root
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: abandoned.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: userGIF.path))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: unrelatedTemporaryFile.path)
        )
    }
}
