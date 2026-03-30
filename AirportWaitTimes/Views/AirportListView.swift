import SwiftUI

struct AirportListView: View {
    @StateObject private var viewModel = AirportListViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: AirportFilter = .all

    enum AirportFilter: String, CaseIterable {
        case all = "All"
        case ice = "ICE Present"
        case reported = "Has Reports"
    }

    var filteredAirports: [Airport] {
        var list = viewModel.airports

        // Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.code.lowercased().contains(q) ||
                $0.name.lowercased().contains(q) ||
                $0.city.lowercased().contains(q)
            }
        }

        // Filter
        switch selectedFilter {
        case .all: break
        case .ice: list = list.filter { $0.ice }
        case .reported: list = list.filter { $0.userWait != nil || $0.socialCount > 0 }
        }

        // Sort: ICE first, then by combined wait desc
        list.sort { a, b in
            if a.ice && !b.ice { return true }
            if !a.ice && b.ice { return false }
            return (a.combinedWait ?? 0) > (b.combinedWait ?? 0)
        }

        return list
    }

    var body: some View {
        NavigationStack {
            List {
                // Title header
                VStack(spacing: 4) {
                    Text("🛫 Airport ")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    + Text("Wait Times")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Real-time US airport security wait times")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)

                // Alert banner
                if let notice = viewModel.notice {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.white)
                            .padding(.top, 2)
                        Text(notice)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.orange.opacity(0.85))
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }

                // Stats bar
                StatsBar(
                    iceCount: viewModel.airports.filter(\.ice).count,
                    userReports: viewModel.totalUserReports,
                    socialReports: viewModel.totalSocialReports,
                    airportCount: viewModel.airports.count
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AirportFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter == .ice ? "🚨 \(filter.rawValue)" :
                                       filter == .reported ? "📊 \(filter.rawValue)" :
                                       filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation { selectedFilter = filter }
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                // Legend
                HStack(spacing: 12) {
                    LegendDot(color: .green, label: "User")
                    LegendDot(color: .red, label: "Reddit")
                    LegendDot(color: .purple, label: "Model")
                    Text("⏱️ 6h freshness")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by airport code or city...", text: $searchText)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }
                .padding(10)
                .background(Color(hex: "18181b"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "3f3f46"), lineWidth: 1)
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)

                // Airport list
                ForEach(filteredAirports) { airport in
                    NavigationLink(destination: AirportDetailView(airport: airport)) {
                        AirportCardView(airport: airport)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0a0a0f"))
            .refreshable {
                await viewModel.loadData()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.orange)
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
            viewModel.startAutoRefresh()
        }
    }
}

// MARK: - Stats Bar
struct StatsBar: View {
    let iceCount: Int
    let userReports: Int
    let socialReports: Int
    let airportCount: Int

    var body: some View {
        HStack(spacing: 8) {
            StatCard(value: "\(iceCount)", label: "ICE", color: .red)
            StatCard(value: "\(userReports)", label: "Reports", color: .orange)
            StatCard(value: "\(socialReports)", label: "Reddit", color: .purple)
            StatCard(value: "\(airportCount)", label: "Airports", color: .blue)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "18181b"))
        .cornerRadius(10)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.purple : Color(hex: "18181b"))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.purple : Color(hex: "3f3f46"), lineWidth: 1)
                )
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}
