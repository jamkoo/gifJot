import Foundation
import XCTest
#if canImport(GifJotCore)
@testable import GifJotCore
#else
@testable import GifJot
#endif

final class RecordingFilenameGeneratorTests: XCTestCase {
    func testBuildsStableLocalFilename() throws {
        let calendar = utcCalendar()
        let date = try XCTUnwrap(
            calendar.date(from: DateComponents(
                year: 2026,
                month: 7,
                day: 16,
                hour: 14,
                minute: 5,
                second: 9
            ))
        )

        XCTAssertEqual(
            RecordingFilenameGenerator.baseName(for: date, calendar: calendar),
            "GifJot 2026-07-16 at 14.05.09"
        )
    }

    func testAddsCollisionSuffixWithoutOverwriting() throws {
        let directory = URL(fileURLWithPath: "/Downloads/GifJot")
        let calendar = utcCalendar()
        let date = try XCTUnwrap(
            calendar.date(from: DateComponents(
                year: 2026,
                month: 7,
                day: 16,
                hour: 14,
                minute: 5,
                second: 9
            ))
        )
        let existing = Set([
            "/Downloads/GifJot/GifJot 2026-07-16 at 14.05.09.gif",
            "/Downloads/GifJot/GifJot 2026-07-16 at 14.05.09-2.gif",
        ])

        let result = RecordingFilenameGenerator.nextAvailableURL(
            in: directory,
            date: date,
            calendar: calendar,
            fileExists: { existing.contains($0) }
        )

        XCTAssertEqual(
            result.lastPathComponent,
            "GifJot 2026-07-16 at 14.05.09-3.gif"
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
