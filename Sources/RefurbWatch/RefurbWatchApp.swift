import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            sender.windows.forEach { $0.makeKeyAndOrderFront(nil) }
        }
        return true
    }
}

@main
struct RefurbWatchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 880, minHeight: 620)
                .alert(
                    "Open Apple’s website?",
                    isPresented: Binding(
                        get: { model.productOpenRequest != nil },
                        set: { isPresented in
                            if !isPresented { model.productOpenRequest = nil }
                        }
                    ),
                    presenting: model.productOpenRequest
                ) { _ in
                    Button("Cancel", role: .cancel) {
                        model.productOpenRequest = nil
                    }
                    Button("Go to Website") {
                        model.openConfirmedProduct()
                    }
                } message: { request in
                    Text("\(request.productName) is available. Apple’s page will open only if you continue.")
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1_080, height: 720)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Start All Monitoring") {
                    model.startAll()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
