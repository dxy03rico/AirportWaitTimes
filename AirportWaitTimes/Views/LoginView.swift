import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0a0a0f"), Color(hex: "1a1a2e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App icon & title
                VStack(spacing: 16) {
                    Text("🛫")
                        .font(.system(size: 72))

                    Text("Airport Wait Times")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Real-time US airport security wait times")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                // Feature highlights
                VStack(spacing: 16) {
                    FeatureRow(icon: "clock.fill", color: .orange,
                               title: "Real-time Wait Times",
                               subtitle: "Crowd-sourced + Reddit + predictive model")
                    FeatureRow(icon: "shield.fill", color: .red,
                               title: "ICE Deployment Alerts",
                               subtitle: "Know which airports have ICE checkpoints")
                    FeatureRow(icon: "chart.bar.fill", color: .purple,
                               title: "Busyness Prediction",
                               subtitle: "AI-powered wait time estimation")
                    FeatureRow(icon: "person.2.fill", color: .green,
                               title: "Community Reports",
                               subtitle: "Share and view real traveler experiences")
                }
                .padding(.horizontal, 32)

                Spacer()

                // Google Sign-In button
                VStack(spacing: 12) {
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.6 : 1)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Text("Only Google account login is supported")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller"
            isLoading = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            isLoading = false

            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to get user info"
                return
            }

            let email = user.profile?.email ?? ""
            let name = user.profile?.name ?? ""
            let avatarURL = user.profile?.imageURL(withDimension: 120)?.absoluteString

            // Send to our backend
            Task {
                await auth.authenticate(
                    idToken: idToken,
                    email: email,
                    name: name,
                    avatarURL: avatarURL
                )
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}
