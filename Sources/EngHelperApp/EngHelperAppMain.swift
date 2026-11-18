import AppKit

@main
enum EngHelperAppMain {
    static func main() {
        MainActor.assumeIsolated {
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate
            // Menu bar only: no Dock icon, no main window (BEH-14,
            // design D-02).
            app.setActivationPolicy(.accessory)
            // `run()` never returns, so the local strong reference
            // keeps the (weakly held) delegate alive for the app's
            // whole lifetime.
            app.run()
        }
    }
}
