import Foundation
import ImageIO
import UniformTypeIdentifiers

enum GIFEncodingError: Error, LocalizedError, Sendable {
    case noFrames
    case couldNotCreateDestination
    case couldNotReadFrame(URL)
    case couldNotFinalize

    var errorDescription: String? {
        switch self {
        case .noFrames:
            "No captured frames were available to encode."
        case .couldNotCreateDestination:
            "GifJot could not create the GIF file."
        case let .couldNotReadFrame(url):
            "GifJot could not read temporary frame \(url.lastPathComponent)."
        case .couldNotFinalize:
            "GifJot could not finish writing the GIF file."
        }
    }
}

protocol GIFEncoding: AnyObject, Sendable {
    func encode(frames: [GIFFrame], to destinationURL: URL) throws
}

final class ImageIOGIFEncoder: GIFEncoding {
    func encode(frames: [GIFFrame], to destinationURL: URL) throws {
        guard !frames.isEmpty else { throw GIFEncodingError.noFrames }
        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            throw GIFEncodingError.couldNotCreateDestination
        }

        let destinationProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0,
            ] as [CFString: Any],
        ]
        CGImageDestinationSetProperties(
            destination,
            destinationProperties as CFDictionary
        )

        for frame in frames {
            guard let source = CGImageSourceCreateWithURL(
                frame.fileURL as CFURL,
                nil
            ), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw GIFEncodingError.couldNotReadFrame(frame.fileURL)
            }

            let frameProperties: [CFString: Any] = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: frame.delay,
                    kCGImagePropertyGIFUnclampedDelayTime: frame.delay,
                ] as [CFString: Any],
            ]
            CGImageDestinationAddImage(
                destination,
                image,
                frameProperties as CFDictionary
            )
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFEncodingError.couldNotFinalize
        }
    }
}

final class GIFEncodingWorker: Sendable {
    private let queue = DispatchQueue(
        label: "com.gifjot.gif-encoding",
        qos: .userInitiated
    )
    private let encoder: GIFEncoding

    init(encoder: GIFEncoding = ImageIOGIFEncoder()) {
        self.encoder = encoder
    }

    func encode(frames: [GIFFrame], to destinationURL: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder] in
                do {
                    try encoder.encode(frames: frames, to: destinationURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
