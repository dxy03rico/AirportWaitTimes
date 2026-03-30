import Foundation
import SwiftUI

/// ViewModel for the airport list — handles data loading and auto-refresh
@MainActor
final class AirportListViewModel: ObservableObject {
    @Published var airports: [Airport] = []
    @Published var notice: String?
    @Published var totalUserReports = 0
    @Published var totalSocialReports = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var refreshTimer: Timer?

    func loadData() async {
        isLoading = true
        do {
            let response = try await APIService.shared.fetchAirports()
            airports = response.airports
            notice = response.notice
            totalUserReports = response.totalUserReports
            totalSocialReports = response.totalSocialReports
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Load error: \(error)")
        }
        isLoading = false
    }

    func startAutoRefresh() {
        // Refresh every 2 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.loadData()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
