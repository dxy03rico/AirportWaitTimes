import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0f").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar & Name
                        VStack(spacing: 12) {
                            if let url = auth.avatarURL, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 64))
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray)
                            }

                            Text(auth.userName ?? "User")
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(auth.userEmail ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // Free access badge
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Free Access")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Text("All features unlocked")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color(hex: "18181b"))
                        .cornerRadius(14)

                        // App info
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ABOUT")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(1)

                            InfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            InfoRow(label: "Data Sources", value: "User reports, Reddit, AI model")
                            InfoRow(label: "Freshness Window", value: "6 hours")
                            InfoRow(label: "Auto Refresh", value: "Every 2 minutes")
                        }
                        .padding(20)
                        .background(Color(hex: "18181b"))
                        .cornerRadius(14)

                        // Sign out
                        Button(action: { auth.signOut() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color(hex: "18181b"))
                            .cornerRadius(10)
                        }

                        // Disclaimer
                        Text("Not affiliated with TSA, DHS, or any government agency.\nFor informational purposes only.")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "3f3f46"))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}
