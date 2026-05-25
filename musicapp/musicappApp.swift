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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
