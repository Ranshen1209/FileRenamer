//
//  FileRenamerApp.swift
//  FileRenamer
//
//  Created by Ariel on 2025/4/27.
//

import SwiftUI
import AppKit

@main
struct FileRenamerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    disableWindowMaximization()
                }
        }
        .windowResizability(.contentMinSize)
    }

    private func disableWindowMaximization() {
        guard let window = NSApplication.shared.windows.first else { return }

        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isHidden = true

    }
}
