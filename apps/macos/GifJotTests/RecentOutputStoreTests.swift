import Foundation
import XCTest
#if canImport(GifJotCore)
@testable import GifJotCore
#else
@testable import GifJot
#endif

@MainActor
final class RecentOutputStoreTests: XCTestCase {
    func testRecordsAndRestoresExistingOutput() {
        withIsolatedDefaults { defaults in
            let outputURL = URL(fileURLWithPath: "/Downloads/GifJot/example.gif")
            let store = RecentOutputStore(
                defaults: defaults,
                fileExists: { $0 == outputURL.path }
            )

            store.record(outputURL)

            XCTAssertEqual(store.restoreLastOutputURL(), outputURL)
        }
    }

    func testMissingOutputIsForgotten() {
        withIsolatedDefaults { defaults in
            let outputURL = URL(fileURLWithPath: "/Downloads/GifJot/missing.gif")
            let store = RecentOutputStore(
                defaults: defaults,
                fileExists: { _ in false }
            )
            store.record(outputURL)

            XCTAssertNil(store.restoreLastOutputURL())

            let laterStore = RecentOutputStore(
                defaults: defaults,
                fileExists: { _ in true }
            )
            XCTAssertNil(laterStore.restoreLastOutputURL())
        }
    }

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "GifJotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}
