//
//  iGotYouApp.swift
//  iGotYou
//
//  Created by Ujjawal Prabhat on 16/09/26.
//

import SwiftUI

@main
struct iGotYouApp: App {
    init() {
        FontRegistrar.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
