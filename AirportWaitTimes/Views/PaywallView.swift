import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: StoreManager
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(hex: "0a0a0f").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🛫")
                            .font(.system(size: 56))

                        Text("Unlock Full Access")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        if let name = auth.userName {
                            Text("Welcome, \(name)!")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 48)

                    // What you get
                    VStack(alignment: .leading, spacing: 14) {
                        Text("WHAT'S INCLUDED")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                            .tracking(1.2)

                        PaywallFeature(icon: "clock.fill", text: "Real-time wait times for 40+ airports")
                        PaywallFeature(icon: "bell.fill", text: "ICE deployment alerts & status")
                        PaywallFeature(icon: "chart.bar.fill", text: "AI busyness prediction model")
                        PaywallFeature(icon: "bubble.left.fill", text: "Reddit & social media reports")
                        PaywallFeature(icon: "pencil.circle.fill", text: "Submit your own wait time reports")
                        PaywallFeature(icon: "arrow.clockwise", text: "Auto-refresh every 2 minutes")
                    }
                    .padding(24)
                    .background(Color(hex: "18181b"))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    // Pricing
                    VStack(spacing: 16) {
                        if store.isEarlyAdopter {
                            // Early adopter pricing
                            VStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("🎉")
                                    Text("EARLY ADOPTER SPECIAL")
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                        .tracking(1)
                                }

                                Text("You're one of the first 100 users!")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$0.99")
                                    .font(.system(size: 14))
                                    .strikethrough()
                                    .foregroundColor(.gray)
                                Text("FREE")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.green)
                            }

                            Text("Early adopter access — no payment needed")
                                .font(.caption)
                                .foregroundColor(.gray)

                            // Free unlock button for early adopters
                            Button(action: claimEarlyAdopter) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text("🎁 Claim Free Access")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(colors: [.green, .mint],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal, 24)

                        } else {
                            // Regular pricing
                            VStack(spacing: 4) {
                                Text("ONE-TIME PURCHASE")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                    .tracking(1)

                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("$")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    Text(store.priceString ?? "0.99")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Text("Lifetime access · No subscription · No ads")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            // Purchase button
                            Button(action: purchase) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text("Purchase Full Access")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(colors: [.purple, .blue],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal, 24)
                        }

                        // Restore purchases
                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }

                    // User count indicator
                    VStack(spacing: 4) {
                        let remaining = max(0, 100 - store.totalUserCount)
                        if remaining > 0 {
                            Text("\(remaining) early adopter spots remaining")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                            ProgressView(value: Double(store.totalUserCount), total: 100)
                                .tint(.orange)
                                .padding(.horizontal, 60)
                        } else {
                            Text("Early adopter offer has ended")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    // Sign out option
                    Button(action: { auth.signOut() }) {
                        Text("Sign out")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private func purchase() {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await store.purchaseFullAccess()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }

    private func claimEarlyAdopter() {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await store.claimEarlyAdopterAccess()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}

struct PaywallFeature: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        }
    }
}
