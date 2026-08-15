import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import UIKit

@MainActor
final class FirebaseAuthService: AuthenticationService {
    private let auth: Auth
    private let database: Firestore

    init(auth: Auth = .auth(), database: Firestore = .firestore()) {
        self.auth = auth
        self.database = database
    }

    func restoreSession() async throws -> AppUser? {
        guard let user = auth.currentUser else { return nil }
        return try await appUser(from: user)
    }

    func signInWithGoogle() async throws -> AppUser {
        let configuration = try GoogleConfiguration.load()
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: configuration.clientID)

        guard let presenter = UIApplication.shared.activeViewController else {
            throw DataServiceFailure(kind: .authorization, message: "Unable to present Google Sign-In")
        }

        let result = try await googleSignIn(presenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw DataServiceFailure(kind: .authorization, message: "Google Sign-In did not return an ID token")
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await auth.signIn(with: credential)
        return try await appUser(from: authResult.user)
    }

    func signOut() async throws {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            throw DataServiceFailure(kind: .authorization, message: error.localizedDescription)
        }
    }

    private func appUser(from user: User) async throws -> AppUser {
        let snapshot = try await database.collection(Constants.usersCollection).document(user.uid).getDocument()
        let roleValue = snapshot.data()?[Constants.roleField] as? String
        let role = AppUser.Role(rawValue: roleValue ?? "") ?? .volunteer

        return .init(
            id: user.uid,
            email: user.email,
            displayName: user.displayName,
            role: role
        )
    }

    private func googleSignIn(presenting presenter: UIViewController) async throws -> GIDSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: DataServiceFailure(kind: .authorization, message: "Google Sign-In was cancelled"))
                }
            }
        }
    }

    private enum Constants {
        static let usersCollection = "users"
        static let roleField = "role"
    }
}

private extension UIApplication {
    var activeViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .keyWindow?
            .rootViewController?
            .topmostPresentedViewController
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow)
    }
}

private extension UIViewController {
    var topmostPresentedViewController: UIViewController {
        presentedViewController?.topmostPresentedViewController ?? self
    }
}
