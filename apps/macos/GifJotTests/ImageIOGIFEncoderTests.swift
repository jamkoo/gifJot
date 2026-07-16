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
        try store.append(image: makeImage(red: 1, green: 0), presentationTime: 1)
        try store.append(image: makeImage(red: 0, green: 1), presentationTime: 1.1)

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

        XCTAssertTrue(
            try store.append(image: makeImage(red: 1, green: 0), presentationTime: 1)
        )
        XCTAssertFalse(
            try store.append(image: makeImage(red: 0, green: 1), presentationTime: 2)
        )
        XCTAssertEqual(store.frames.count, 1)

        store.cleanup()

        XCTAssertFalse(FileManager.default.fileExists(atPath: sessionDirectory.path))
        XCTAssertTrue(store.frames.isEmpty)
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
