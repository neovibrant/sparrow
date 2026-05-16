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
    var body: some Scene {
        MenuBarExtra("sparrow", systemImage: "bird") {
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
