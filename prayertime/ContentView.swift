//
//  ContentView.swift
//  prayertime
//
//  Created by Md. Abu Sufian Sufi on 11/15/24.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var settings = PrayerSettings()
    
    var body: some View {
        NavigationView {
            SettingsView(settings: settings)
                .navigationTitle("Prayer Times Settings")
        }
    }
}

#Preview {
    ContentView()
}
