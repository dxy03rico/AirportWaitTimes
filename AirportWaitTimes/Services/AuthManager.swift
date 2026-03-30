import Foundation
import GoogleSignIn
import SwiftUI

/// Manages Google Sign-In authentication state
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isSignedIn = false
    @Published var userName: String?
    @Published var userEmail: String?
    @Published var avatarURL: String?
    @Published var userId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
        // Check for existing session
        restorePreviousSignIn()
    }

    // MARK: - Restore session
    func restorePreviousSignIn() {
        // Check if we have a stored token
        if let token = UserDefaults.standard.string(forKey: "auth_token"),
           !token.isEmpty {
            // Restore cached user info
            userName = UserDefaults.standard.string(forKey: "user_name")
            userEmail = UserDefaults.standard.string(forKey: "user_email")
            avatarURL = UserDefaults.standard.string(forKey: "user_avatar")
            userId = UserDefaults.standard.string(forKey: "user_id")
            isSignedIn = true
        }

        // Also try to restore Google session silently
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            // If Google session is valid but we lost our app token, re-auth
            if let user = user, self?.isSignedIn == false {
                Task { @MainActor in
                    guard let idToken = user.idToken?.tokenString else { return }
                    await self?.authenticate(
                        idToken: idToken,
                        email: user.profile?.email ?? "",
                        name: user.profile?.name ?? "",
                        avatarURL: user.profile?.imageURL(withDimension: 120)?.absoluteString
                    )
                }
            }
        }
    }

    // MARK: - Authenticate with backend
    func authenticate(idToken: String, email: String, name: String, avatarURL: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIService.shared.authenticateWithGoogle(
                idToken: idToken,
                email: email,
                name: name,
                avatarURL: avatarURL
            )

            // Store user info
            self.userName = response.user.name
            self.userEmail = response.user.email
            self.avatarURL = response.user.avatarURL
            self.userId = response.user.id
            self.isSignedIn = true

            // Persist
            UserDefaults.standard.set(response.user.name, forKey: "user_name")
            UserDefaults.standard.set(response.user.email, forKey: "user_email")
            UserDefaults.standard.set(response.user.avatarURL, forKey: "user_avatar")
            UserDefaults.standard.set(response.user.id, forKey: "user_id")

            // Update store manager
            StoreManager.shared.totalUserCount = response.totalUsers
            StoreManager.shared.isEarlyAdopter = response.user.isEarlyAdopter
            if response.user.isPaid || response.user.isEarlyAdopter {
                StoreManager.shared.isUnlocked = true
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()

        isSignedIn = false
        userName = nil
        userEmail = nil
        avatarURL = nil
        userId = nil

        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_avatar")
        UserDefaults.standard.removeObject(forKey: "user_id")

        // Reset store
        StoreManager.shared.isUnlocked = false
        StoreManager.shared.isEarlyAdopter = false
    }
}
