import AppKit
import Foundation

@MainActor
protocol FileClipboardWriting: AnyObject {
    func writeFile(at url: URL) -> Bool
}

@MainActor
final class MacFileClipboardWriter: FileClipboardWriting {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func writeFile(at url: URL) -> Bool {
        pasteboard.clearContents()
        return pasteboard.writeObjects([url as NSURL])
    }
}
