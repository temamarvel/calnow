//
//  calnowApp.swift
//  calnow
//
//  Created by Артем Денисов on 03.11.2025.
//

import SwiftUI
import SwiftData

@main
struct calnowApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
        .modelContainer(for: UserProfile.self)
    }
}
