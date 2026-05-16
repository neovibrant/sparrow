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
    
    var body: some Scene {
        MenuBarExtra {
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(nsImage: SparrowIcon.image)
        }
    }
}
