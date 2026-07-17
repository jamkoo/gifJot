import Foundation

@MainActor
final class RecentOutputStore {
    typealias FileExists = @MainActor (String) -> Bool

    private enum Key {
        static let lastOutputPath = "recentOutput.lastOutputPath"
    }

    private let defaults: UserDefaults
    private let fileExists: FileExists

    init(
        defaults: UserDefaults = .standard,
        fileExists: @escaping FileExists = {
            FileManager.default.fileExists(atPath: $0)
        }
    ) {
        self.defaults = defaults
        self.fileExists = fileExists
    }

    func restoreLastOutputURL() -> URL? {
        guard let path = defaults.string(forKey: Key.lastOutputPath),
              fileExists(path)
        else {
            defaults.removeObject(forKey: Key.lastOutputPath)
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    func record(_ url: URL) {
        defaults.set(url.path, forKey: Key.lastOutputPath)
    }
}
