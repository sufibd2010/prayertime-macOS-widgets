//
//  prayertimeApp.swift
//  prayertime
//
//  Created by Md. Abu Sufian Sufi on 11/15/24.
//

import SwiftUI

@main
struct prayertimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle deep linking from widget
                    if url.scheme == "prayertime" && url.host == "settings" {
                        90.399452                        // This will open the settings view
                        print("Opening settings from widget")
                    }
                }
        }
    }
}
