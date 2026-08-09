//
//  ContentView.swift
//  HappyPaw
//
//  Created by Александр Коротков on 16.06.2026.
//

import SwiftUI

struct ContentView: View {
    let launchStore: LaunchStore
    let onboardingStore: OnboardingStore
    let mainAdministratorScreenStore: MainAdministratorScreenStore

    var body: some View {
        Group {
            switch launchStore.state.destination {
            case nil:
                LaunchView(store: launchStore)
            case .onboarding:
                if onboardingStore.state.isCompleted {
                    MainAdministratorScreenView(store: mainAdministratorScreenStore)
                } else {
                    OnboardingView(store: onboardingStore)
                }
            case .mainAdministrator:
                MainAdministratorScreenView(store: mainAdministratorScreenStore)
            }
        }
    }
}

#Preview {
    ContentView(
        launchStore: LaunchStore(),
        onboardingStore: OnboardingStore(),
        mainAdministratorScreenStore: MainAdministratorScreenStore()
    )
}
