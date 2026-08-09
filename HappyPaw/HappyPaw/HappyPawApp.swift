//
//  HappyPawApp.swift
//  HappyPaw
//
//  Created by Александр Коротков on 16.06.2026.
//

import SwiftUI

@main
struct HappyPawApp: App {
    // Composition root: the app owns long-lived MVI stores and injects them into screens.
    @State private var launchStore = LaunchStore()
    @State private var onboardingStore = OnboardingStore(
        persistCompletion: {
            UserDefaults.standard.set(true, forKey: Constants.hasCompletedOnboardingKey)
        }
    )
    @State private var mainAdministratorScreenStore = MainAdministratorScreenStore()

    var body: some Scene {
        WindowGroup {
            ContentView(
                launchStore: launchStore,
                onboardingStore: onboardingStore,
                mainAdministratorScreenStore: mainAdministratorScreenStore
            )
        }
    }

    private enum Constants {
        static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    }
}
