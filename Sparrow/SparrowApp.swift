//
//  SparrowApp.swift
//  Sparrow
//
//  Created by Vladimir on 16/05/2026.
//

import SwiftUI
import AppKit

@main
struct SparrowApp: App {
    private let mouseRemapper = MouseRemapper()
    @StateObject private var settings = SparrowSettings.shared
    @Environment(\.openSettings) private var openSettings
    
    var body: some Scene {
        MenuBarExtra {
            Button("About Sparrow") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
                NSApplication.shared.activate()
            }

            Divider()

            Button("Settings...") {
                openSettings()
            }

            Divider()

            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(nsImage: SparrowIcon.image)
        }

        Settings {
            SettingsView(settings: settings)
        }
    }
}
