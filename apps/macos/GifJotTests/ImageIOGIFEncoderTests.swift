import CoreGraphics
import Foundation
import ImageIO
import XCTest
@testable import GifJot

final class ImageIOGIFEncoderTests: XCTestCase {
    func testEncodesTemporaryFramesIntoAnimatedGif() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let store = TemporaryRecordingStore(
            baseDirectory: root.appendingPathComponent("frames"),
            maximumFrameCount: 2
        )
        try store.beginSession()
        XCTAssertEqual(
            try store.append(
                image: makeImage(red: 1, green: 0),
                presentationTime: 1
            ),
            .stored
        )
        XCTAssertEqual(
            try store.append(
                image: makeImage(red: 0, green: 1),
                presentationTime: 1.1
            ),
            .stored
        )

        let frames = GIFFrameTiming.makeFrames(
            from: store.frames,
            defaultDelay: 0.1
        )
        let outputURL = root.appendingPathComponent("output.gif")
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        try ImageIOGIFEncoder().encode(frames: frames, to: outputURL)

        let source = try XCTUnwrap(
            CGImageSourceCreateWithURL(outputURL as CFURL, nil)
        )
        XCTAssertEqual(CGImageSourceGetCount(source), 2)
    }

    func testTemporaryStoreEnforcesFrameBoundAndCleansSession() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let store = TemporaryRecordingStore(
            baseDirectory: root,
            maximumFrameCount: 1
        )
        try store.beginSession()
        let sessionDirectory = try XCTUnwrap(store.sessionDirectory)

        XCTAssertEqual(
            try store.append(image: makeImage(red: 1, green: 0), presentationTime: 1),
            .stored
        )
        XCTAssertEqual(
            try store.append(image: makeImage(red: 0, green: 1), presentationTime: 2),
            .capacityReached
        )
        XCTAssertEqual(store.frames.count, 1)

        store.cleanup()

        XCTAssertFalse(FileManager.default.fileExists(atPath: sessionDirectory.path))
        XCTAssertTrue(store.frames.isEmpty)
    }

    func testTemporaryStoreCoalescesOnlyConsecutiveExactDuplicates() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let store = TemporaryRecordingStore(
            baseDirectory: root,
            maximumFrameCount: 4
        )
        try store.beginSession()

        XCTAssertEqual(
            try store.append(image: makeImage(red: 1, green: 0), presentationTime: 1),
            .stored
        )
        XCTAssertEqual(
            try store.append(image: makeImage(red: 1, green: 0), presentationTime: 1.1),
            .duplicate
        )
        XCTAssertEqual(
            try store.append(image: makeImage(red: 0, green: 1), presentationTime: 1.2),
            .stored
        )
        XCTAssertEqual(
            try store.append(image: makeImage(red: 1, green: 0), presentationTime: 1.3),
            .stored
        )

        XCTAssertEqual(store.frames.count, 3)
        XCTAssertEqual(store.duplicateFrameCount, 1)
        XCTAssertEqual(store.frames.map(\.presentationTime), [1, 1.2, 1.3])
    }

    func testDuplicateFramesExtendThePreviousFrameTiming() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "GifJotTests-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let store = TemporaryRecordingStore(baseDirectory: root)
        try store.beginSession()
        let stillFrame = makeImage(red: 1, green: 0)

        XCTAssertEqual(
            try store.append(image: stillFrame, presentationTime: 5),
            .stored
        )
        XCTAssertEqual(
            try store.append(image: stillFrame, presentationTime: 5.1),
            .duplicate
        )
        XCTAssertEqual(
            try store.append(image: stillFrame, presentationTime: 5.2),
            .duplicate
        )

        let frames = GIFFrameTiming.makeFrames(
            from: store.frames,
            defaultDelay: 0.1,
            endingPresentationTime: 5.3
        )

        XCTAssertEqual(frames.count, 1)
        XCTAssertEqual(frames[0].delay, 0.3, accuracy: 0.000_001)
    }

    private func makeImage(red: CGFloat, green: CGFloat) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 4,
            height: 4,
            bitsPerComponent: 8,
            bytesPerRow: 16,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(
            CGColor(
                colorSpace: colorSpace,
                components: [red, green, 0, 1]
            )!
        )
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        return context.makeImage()!
    }
}
