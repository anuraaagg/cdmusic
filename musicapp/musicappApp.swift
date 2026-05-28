//
//  musicappApp.swift
//  musicapp
//
//  Created by Anurag Singh on 22/05/26.
//

import SwiftUI

@main
struct musicappApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if DEBUG
enum LaunchSelfTests {
    /// Runs after the first frame — never block cold launch on disk I/O or graph layout.
    static func runDeferred() {
        Task.detached(priority: .background) {
            let crateFailures = SavedCrateStoreTests.run()
            if !crateFailures.isEmpty {
                print("[SavedCrateStoreTests]", crateFailures.joined(separator: "; "))
            }
            let webFailures = SavedCrateWebGraphTests.run()
            if !webFailures.isEmpty {
                print("[SavedCrateWebGraphTests]", webFailures.joined(separator: "; "))
            }
            let crateLayoutFailures = MilkCrateStackLayoutTests.run()
            if !crateLayoutFailures.isEmpty {
                print("[MilkCrateStackLayoutTests]", crateLayoutFailures.joined(separator: "; "))
            }
        }
    }
}
#endif
