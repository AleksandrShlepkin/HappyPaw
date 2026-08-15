import SwiftUI
import UIKit

@MainActor
final class PlaceholderFlowCoordinator: MainFlowCoordinating {
    let rootViewController: UIViewController
    private let navigationController: UINavigationController
    private let tab: MainTab
    private let message: String

    init(tab: MainTab, message: String) {
        self.tab = tab
        self.message = message
        let navigationController = UINavigationController()
        self.navigationController = navigationController
        self.rootViewController = navigationController
        navigationController.tabBarItem = UITabBarItem(
            title: tab.title,
            image: tab.image,
            tag: tab.rawValue
        )
    }

    func start() {
        let view = ContentUnavailableView(tab.title, systemImage: "pawprint", description: Text(message))
            .navigationTitle(tab.title)
        navigationController.setViewControllers([UIHostingController(rootView: view)], animated: false)
    }

    func handle(_ route: AppRoute) {
        navigationController.popToRootViewController(animated: false)
    }
}

@MainActor
final class ProfileFlowCoordinator: MainFlowCoordinating {
    let rootViewController: UIViewController
    private let navigationController: UINavigationController
    private let store: MainAdministratorScreenStore

    init(store: MainAdministratorScreenStore) {
        self.store = store
        let navigationController = UINavigationController()
        self.navigationController = navigationController
        self.rootViewController = navigationController
        navigationController.tabBarItem = UITabBarItem(
            title: MainTab.profile.title,
            image: MainTab.profile.image,
            tag: MainTab.profile.rawValue
        )
    }

    func start() {
        navigationController.setViewControllers(
            [UIHostingController(rootView: MainAdministratorScreenView(store: store))],
            animated: false
        )
    }

    func handle(_ route: AppRoute) {
        navigationController.popToRootViewController(animated: false)
    }
}
