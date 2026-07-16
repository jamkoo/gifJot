import Foundation
import XCTest
@testable import GifJot

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testDefaultsMatchProductDefaults() {
        withIsolatedDefaults { defaults in
            let store = SettingsStore(defaults: defaults)

            XCTAssertEqual(store.qualityPreset, .balanced)
            XCTAssertEqual(store.maximumOutputWidth, .width960)
            XCTAssertEqual(store.framesPerSecond, .fps15)
            XCTAssertTrue(store.includeCursor)
            XCTAssertEqual(store.countdown, .oneSecond)
            XCTAssertTrue(store.copyAfterRecording)
        }
    }

    func testChangesPersist() {
        withIsolatedDefaults { defaults in
            var store: SettingsStore? = SettingsStore(defaults: defaults)
            store?.qualityPreset = .small
            store?.maximumOutputWidth = .width640
            store?.framesPerSecond = .fps10
            store?.includeCursor = false
            store?.countdown = .off
            store?.copyAfterRecording = false

            store = SettingsStore(defaults: defaults)

            XCTAssertEqual(store?.qualityPreset, .small)
            XCTAssertEqual(store?.maximumOutputWidth, .width640)
            XCTAssertEqual(store?.framesPerSecond, .fps10)
            XCTAssertEqual(store?.includeCursor, false)
            XCTAssertEqual(store?.countdown, .off)
            XCTAssertEqual(store?.copyAfterRecording, false)
        }
    }

    func testRestoreDefaultsResetsEverySetting() {
        withIsolatedDefaults { defaults in
            let store = SettingsStore(defaults: defaults)
            store.qualityPreset = .highQuality
            store.maximumOutputWidth = .original
            store.framesPerSecond = .fps20
            store.includeCursor = false
            store.countdown = .threeSeconds
            store.copyAfterRecording = false

            store.restoreDefaults()

            XCTAssertEqual(store.qualityPreset, .balanced)
            XCTAssertEqual(store.maximumOutputWidth, .width960)
            XCTAssertEqual(store.framesPerSecond, .fps15)
            XCTAssertTrue(store.includeCursor)
            XCTAssertEqual(store.countdown, .oneSecond)
            XCTAssertTrue(store.copyAfterRecording)
        }
    }

    func testBuildsImmutableRecordingConfiguration() {
        withIsolatedDefaults { defaults in
            let store = SettingsStore(defaults: defaults)
            store.maximumOutputWidth = .width640
            store.framesPerSecond = .fps10
            store.includeCursor = false
            store.countdown = .threeSeconds
            store.copyAfterRecording = false

            let configuration = store.recordingConfiguration()

            XCTAssertEqual(configuration.maximumOutputWidth, 640)
            XCTAssertEqual(configuration.framesPerSecond, 10)
            XCTAssertFalse(configuration.includeCursor)
            XCTAssertEqual(configuration.countdownSeconds, 3)
            XCTAssertFalse(configuration.copyAfterRecording)
        }
    }

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "GifJotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}
