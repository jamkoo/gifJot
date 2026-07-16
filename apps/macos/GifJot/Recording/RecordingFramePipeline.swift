import CoreImage
import CoreMedia
import Foundation
import ScreenCaptureKit

enum RecordingFramePipelineError: Error, LocalizedError, Sendable {
    case couldNotCreateImage
    case noFrames

    var errorDescription: String? {
        switch self {
        case .couldNotCreateImage:
            "GifJot could not process a captured frame."
        case .noFrames:
            "The recording stopped before GifJot captured a complete frame."
        }
    }
}

struct RecordingFramePipelineResult: Equatable, Sendable {
    let frames: [GIFFrame]
    let droppedFrames: Int
}

struct BoundedFrameAdmission: Equatable, Sendable {
    let capacity: Int
    private(set) var pendingCount = 0
    private(set) var droppedCount = 0

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    mutating func admit() -> Bool {
        guard pendingCount < capacity else {
            droppedCount += 1
            return false
        }

        pendingCount += 1
        return true
    }

    mutating func complete() {
        pendingCount = max(0, pendingCount - 1)
    }

    mutating func recordDrop() {
        droppedCount += 1
    }
}

final class RecordingFramePipeline: @unchecked Sendable {
    private let processingQueue = DispatchQueue(
        label: "com.gifjot.frame-processing",
        qos: .userInitiated
    )
    private let context = CIContext()
    private let store: TemporaryRecordingStore
    private let stateLock = NSLock()

    private var admission: BoundedFrameAdmission
    private var acceptingFrames = false
    private var processingError: Error?
    private var latestPresentationTime: TimeInterval?

    init(
        store: TemporaryRecordingStore = TemporaryRecordingStore(),
        maximumPendingFrames: Int = 4
    ) {
        self.store = store
        admission = BoundedFrameAdmission(capacity: maximumPendingFrames)
    }

    func prepare() async throws {
        try await withCheckedThrowingContinuation { continuation in
            processingQueue.async { [self] in
                do {
                    try store.beginSession()
                    stateLock.lock()
                    acceptingFrames = true
                    stateLock.unlock()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func submit(_ sampleBuffer: CMSampleBuffer) {
        guard let observation = Self.observation(for: sampleBuffer) else {
            return
        }

        stateLock.lock()
        latestPresentationTime = observation.presentationTime
        guard observation.isComplete else {
            stateLock.unlock()
            return
        }
        guard acceptingFrames else {
            stateLock.unlock()
            return
        }
        guard admission.admit() else {
            stateLock.unlock()
            return
        }

        processingQueue.async { [self] in
            process(
                sampleBuffer,
                presentationTime: observation.presentationTime
            )
        }
        stateLock.unlock()
    }

    func finish(defaultFrameDelay: TimeInterval) async throws
        -> RecordingFramePipelineResult
    {
        try await withCheckedThrowingContinuation { continuation in
            stateLock.lock()
            acceptingFrames = false
            processingQueue.async { [self] in
                stateLock.lock()
                let error = processingError
                let droppedFrames = admission.droppedCount
                let endingPresentationTime = latestPresentationTime
                stateLock.unlock()

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let frames = GIFFrameTiming.makeFrames(
                    from: store.frames,
                    defaultDelay: defaultFrameDelay,
                    endingPresentationTime: endingPresentationTime
                )
                guard !frames.isEmpty else {
                    continuation.resume(
                        throwing: RecordingFramePipelineError.noFrames
                    )
                    return
                }

                continuation.resume(
                    returning: RecordingFramePipelineResult(
                        frames: frames,
                        droppedFrames: droppedFrames
                    )
                )
            }
            stateLock.unlock()
        }
    }

    func cleanup() async {
        await withCheckedContinuation { continuation in
            stateLock.lock()
            acceptingFrames = false
            processingQueue.async { [store] in
                store.cleanup()
                continuation.resume()
            }
            stateLock.unlock()
        }
    }

    private func process(
        _ sampleBuffer: CMSampleBuffer,
        presentationTime: TimeInterval
    ) {
        defer {
            stateLock.lock()
            admission.complete()
            stateLock.unlock()
        }

        do {
            let didStore: Bool = try autoreleasepool {
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                else {
                    throw RecordingFramePipelineError.couldNotCreateImage
                }

                let image = CIImage(cvPixelBuffer: pixelBuffer)
                guard let cgImage = context.createCGImage(
                    image,
                    from: image.extent
                ) else {
                    throw RecordingFramePipelineError.couldNotCreateImage
                }

                return try store.append(
                    image: cgImage,
                    presentationTime: presentationTime
                )
            }

            if !didStore {
                stateLock.lock()
                admission.recordDrop()
                stateLock.unlock()
            }
        } catch {
            stateLock.lock()
            if processingError == nil {
                processingError = error
            }
            stateLock.unlock()
        }
    }

    private static func observation(
        for sampleBuffer: CMSampleBuffer
    ) -> (isComplete: Bool, presentationTime: TimeInterval)? {
        guard CMSampleBufferIsValid(sampleBuffer),
              CMSampleBufferDataIsReady(sampleBuffer),
              CMSampleBufferGetImageBuffer(sampleBuffer) != nil,
              let attachmentArrays = CMSampleBufferGetSampleAttachmentsArray(
                  sampleBuffer,
                  createIfNecessary: false
              ) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentArrays.first,
              let statusRawValue = attachments[.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue)
        else {
            return nil
        }

        let time = CMTimeGetSeconds(
            CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        )
        guard time.isFinite else { return nil }
        return (status == .complete, time)
    }
}
