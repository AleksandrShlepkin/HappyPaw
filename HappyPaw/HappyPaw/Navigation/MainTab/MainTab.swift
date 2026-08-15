import UIKit

enum MainTab: Int, CaseIterable {
    case cards
    case favorites
    case activity
    case profile

    var title: String {
        switch self {
        case .cards: "Карточки"
        case .favorites: "Избранное"
        case .activity: "Активность"
        case .profile: "Профиль"
        }
    }

    var image: UIImage? {
        let systemName = switch self {
        case .cards: "rectangle.stack"
        case .favorites: "heart"
        case .activity: "clock.arrow.circlepath"
        case .profile: "person"
        }
        return UIImage(systemName: systemName)
    }
}
