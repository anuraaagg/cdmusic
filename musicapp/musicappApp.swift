//
//  musicappApp.swift
//  musicapp
//
//  Created by Anurag Singh on 22/05/26.
//

import SwiftUI

@main
struct musicappApp: App {
    init() {
        GoogleFontsRegistrar.registerBundledFonts()
        #if DEBUG
        let crateFailures = SavedCrateStoreTests.run()
        if !crateFailures.isEmpty {
            print("[SavedCrateStoreTests]", crateFailures.joined(separator: "; "))
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
