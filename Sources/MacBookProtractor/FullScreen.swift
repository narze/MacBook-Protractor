import AppKit

@MainActor
enum FullScreen {
    /// The main app window (the menu bar item has no titled window).
    static var window: NSWindow? {
        NSApp.mainWindow ?? NSApp.windows.first { $0.isVisible && $0.styleMask.contains(.titled) }
    }

    static func toggle() {
        window?.toggleFullScreen(nil)
    }

    static func enter() {
        guard let window, !window.styleMask.contains(.fullScreen) else { return }
        window.toggleFullScreen(nil)
    }
}
