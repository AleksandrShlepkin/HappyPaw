import SwiftUI
import UIKit

@MainActor
final class MainTabBarCoordinator: Coordinator, AppRouteHandling {
    let rootViewController: UIViewController

    private let tabBarController: UITabBarController
    private let dependencies: AppDependencyProviding
    private var flows: [MainTab: any MainFlowCoordinating] = [:]

    init(dependencies: AppDependencyProviding) {
        self.dependencies = dependencies
        let tabBarController = UITabBarController()
        self.tabBarController = tabBarController
        self.rootViewController = tabBarController
    }

    func start() {
        let cards = CardsFlowCoordinator()
        let favorites = PlaceholderFlowCoordinator(
            tab: .favorites,
            message: "Здесь появятся избранные карточки"
        )
        let activity = PlaceholderFlowCoordinator(
            tab: .activity,
            message: "Здесь появится история действий"
        )
        let profile = ProfileFlowCoordinator(
            store: dependencies.mainAdministratorScreenStore
        )

        flows = [
            .cards: cards,
            .favorites: favorites,
            .activity: activity,
            .profile: profile
        ]

        MainTab.allCases.forEach { flows[$0]?.start() }
        tabBarController.setViewControllers(
            MainTab.allCases.compactMap { flows[$0]?.rootViewController },
            animated: false
        )
    }

    func handle(_ route: AppRoute) {
        let tab: MainTab = switch route {
        case .cards, .cardDetails, .editCard: .cards
        case .favorites: .favorites
        case .activity: .activity
        case .profile: .profile
        }

        tabBarController.selectedIndex = tab.rawValue
        flows[tab]?.handle(route)
    }
}

@MainActor
protocol MainFlowCoordinating: Coordinator {
    func handle(_ route: AppRoute)
}

struct MainTabBarContainer: UIViewControllerRepresentable {
    let dependencies: AppDependencyProviding

    func makeCoordinator() -> MainTabBarCoordinator {
        MainTabBarCoordinator(dependencies: dependencies)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.start()
        return context.coordinator.rootViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
