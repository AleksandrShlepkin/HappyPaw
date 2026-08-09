//
//  OnboardingPages.swift
//  HappyPaw
//
//  Created by Александр Коротков on 07.08.2026.
//

import Foundation

struct OnboardingPage: Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: Constants.dailyCareTitle,
            icon: Constants.dailyCareIcon,
            description: Constants.dailyCareDescription
        ),
        OnboardingPage(
            title: Constants.remindersTitle,
            icon: Constants.remindersIcon,
            description: Constants.remindersDescription
        ),
        OnboardingPage(
            title: Constants.alwaysHereTitle,
            icon: Constants.alwaysHereIcon,
            description: Constants.alwaysHereDescription
        )
    ]

    private enum Constants {
        static let dailyCareTitle = "Забота каждый день"
        static let dailyCareIcon = "pawprint.fill"
        static let dailyCareDescription = "Всё необходимое для вашего питомца"
        static let remindersTitle = "Полезные напоминания"
        static let remindersIcon = "calendar"
        static let remindersDescription = "Кормление, прогулки и лекарства"
        static let alwaysHereTitle = "Всегда рядом"
        static let alwaysHereIcon = "heart.fill"
        static let alwaysHereDescription = "Важная информация в одном месте"
    }
}
