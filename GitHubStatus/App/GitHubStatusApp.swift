import SwiftUI
import AppKit

@main
struct GitHubStatusApp: App {
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var viewModel: StatusViewModel

    init() {
        let cm = ConfigurationManager.shared
        _configManager = StateObject(wrappedValue: cm)
        _viewModel = StateObject(wrappedValue: StatusViewModel(configManager: cm))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel, configManager: configManager)
        } label: {
            Image(systemName: viewModel.menuBarIconName)
        }
        .menuBarExtraStyle(.window)
    }
}

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func open(configManager: ConfigurationManager, onConfigChange: @escaping () -> Void) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(configManager: configManager, onConfigChange: onConfigChange)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "GitHub Status Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.center()

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        self.window = window

        // Revert to accessory when settings window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
