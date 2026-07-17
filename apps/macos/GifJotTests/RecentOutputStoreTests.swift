import Foundation
import XCTest
#if canImport(GifJotCore)
@testable import GifJotCore
#else
@testable import GifJot
#endif

final class RecentOutputStoreTests: XCTestCase {
    func testRecordsAndRestoresExistingOutput() async {
        await MainActor.run {
            Self.withIsolatedDefaults { defaults in
                let outputURL = URL(fileURLWithPath: "/Downloads/GifJot/example.gif")
                let store = RecentOutputStore(
                    defaults: defaults,
                    fileExists: { $0 == outputURL.path }
                )

                store.record(outputURL)

                XCTAssertEqual(store.restoreLastOutputURL(), outputURL)
            }
        }
    }

    func testMissingOutputIsForgotten() async {
        await MainActor.run {
            Self.withIsolatedDefaults { defaults in
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
    }

    private static func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "GifJotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}
