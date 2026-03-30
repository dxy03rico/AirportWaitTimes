import SwiftUI

/// Root navigation: Login → Main app (free, no paywall)
struct RootView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        Group {
            if !auth.isSignedIn {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isSignedIn)
    }
}
