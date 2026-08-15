import SwiftUI
import UIKit

@MainActor
final class CardsFlowCoordinator: MainFlowCoordinating {
    let rootViewController: UIViewController
    private let navigationController: UINavigationController

    init() {
        let navigationController = UINavigationController()
        self.navigationController = navigationController
        self.rootViewController = navigationController
        navigationController.tabBarItem = UITabBarItem(
            title: MainTab.cards.title,
            image: MainTab.cards.image,
            tag: MainTab.cards.rawValue
        )
    }

    func start() {
        navigationController.setViewControllers([makeList()], animated: false)
    }

    func handle(_ route: AppRoute) {
        switch route {
        case .cards:
            popToList()
        case let .cardDetails(id):
            navigationController.setViewControllers([makeList(), makeDetails(id: id)], animated: false)
        case let .editCard(id):
            // Supports jumping over intermediate screens while preserving a
            // natural back stack: list -> details -> edit.
            navigationController.setViewControllers(
                [makeList(), makeDetails(id: id), makeEditor(id: id)],
                animated: false
            )
        default:
            break
        }
    }

    private func makeList() -> UIViewController {
        UIHostingController(rootView: CardsListView(
            onSelect: { [weak self] id in self?.showDetails(id: id) }
        ))
    }

    private func makeDetails(id: String) -> UIViewController {
        UIHostingController(rootView: CardDetailsView(
            cardID: id,
            onEdit: { [weak self] in self?.showEditor(id: id) }
        ))
    }

    private func makeEditor(id: String) -> UIViewController {
        UIHostingController(rootView: CardEditorView(
            cardID: id,
            onFinish: { [weak self] in self?.popToList() }
        ))
    }

    private func showDetails(id: String) {
        navigationController.pushViewController(makeDetails(id: id), animated: true)
    }

    private func showEditor(id: String) {
        navigationController.pushViewController(makeEditor(id: id), animated: true)
    }

    private func popToList() {
        navigationController.popToRootViewController(animated: true)
    }
}

private struct CardsListView: View {
    let onSelect: (String) -> Void

    var body: some View {
        List(1...6, id: \.self) { id in
            Button("Карточка питомца №\(id)") { onSelect(String(id)) }
        }
        .navigationTitle("Карточки")
    }
}

private struct CardDetailsView: View {
    let cardID: String
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "pawprint.fill").font(.system(size: 64))
            Text("Карточка №\(cardID)").font(.title.bold())
            Button("Редактировать", action: onEdit).buttonStyle(.borderedProminent)
        }
        .navigationTitle("Детали")
    }
}

private struct CardEditorView: View {
    let cardID: String
    let onFinish: () -> Void
    @State private var name = "Питомец"

    var body: some View {
        Form {
            TextField("Имя", text: $name)
            Button("Сохранить и вернуться к списку", action: onFinish)
        }
        .navigationTitle("Редактирование №\(cardID)")
    }
}
