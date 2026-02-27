import SwiftUI

@main
struct TinyCEOAppMain: App {
    @NSApplicationDelegateAdaptor(MenuBarAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
