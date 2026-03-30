import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        TabView {
            AirportListView()
                .tabItem {
                    Label("Airports", systemImage: "airplane.departure")
                }

            ReportWaitTimeView()
                .tabItem {
                    Label("Report", systemImage: "square.and.pencil")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .tint(.orange)
    }
}
