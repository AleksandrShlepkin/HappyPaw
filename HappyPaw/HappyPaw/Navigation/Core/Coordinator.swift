import UIKit

@MainActor
protocol Coordinator: AnyObject {
    var rootViewController: UIViewController { get }
    func start()
}

/// Composition seam for feature dependencies. A Needle component can conform to
/// this protocol later without leaking the DI framework into navigation code.
@MainActor
protocol AppDependencyProviding: AnyObject {
    var mainAdministratorScreenStore: MainAdministratorScreenStore { get }
}

@MainActor
final class AppDependencies: AppDependencyProviding {
    let mainAdministratorScreenStore: MainAdministratorScreenStore

    init(mainAdministratorScreenStore: MainAdministratorScreenStore) {
        self.mainAdministratorScreenStore = mainAdministratorScreenStore
    }
}
