import SwiftUI
import GoogleSignIn

@main
struct AirportWaitTimesApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var storeManager = StoreManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(storeManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
