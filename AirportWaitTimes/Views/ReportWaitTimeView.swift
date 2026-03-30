import SwiftUI

struct ReportWaitTimeView: View {
    @State private var selectedCode: String = ""
    @State private var waitMinutes: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @StateObject private var viewModel = AirportListViewModel()

    private let airportCodes = [
        "ATL", "IAH", "ORD", "DFW", "DEN", "JFK", "LAX", "SFO", "MIA", "SEA",
        "EWR", "MCO", "LGA", "PHX", "CLT", "LAS", "MSP", "DTW", "BOS", "PHL",
        "FLL", "BWI", "IAD", "DCA", "SLC", "SAN", "TPA", "PDX", "HNL", "AUS",
        "BNA", "MSY", "RDU", "STL", "SJC", "OAK", "PIT", "IND", "CLE", "CMH"
    ]

    var filteredCodes: [String] {
        if searchText.isEmpty { return airportCodes }
        return airportCodes.filter { $0.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0f").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("Report Wait Time")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Help fellow travelers with real-time data")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)

                        // Airport picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SELECT AIRPORT")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(1)

                            TextField("Search airport code...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.characters)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(filteredCodes, id: \.self) { code in
                                        Button(action: { selectedCode = code }) {
                                            Text(code)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(selectedCode == code ? Color.orange : Color(hex: "27272a"))
                                                .foregroundColor(selectedCode == code ? .black : .white)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .frame(height: 40)
                        }
                        .padding(16)
                        .background(Color(hex: "18181b"))
                        .cornerRadius(14)

                        // Wait time input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WAIT TIME")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(1)

                            HStack(spacing: 12) {
                                TextField("0", text: $waitMinutes)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 100)
                                    .padding()
                                    .background(Color(hex: "27272a"))
                                    .cornerRadius(12)

                                Text("minutes")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)

                            // Quick buttons
                            HStack(spacing: 8) {
                                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { min in
                                    Button("\(min)m") {
                                        waitMinutes = "\(min)"
                                    }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "27272a"))
                                    .foregroundColor(.orange)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "18181b"))
                        .cornerRadius(14)

                        // Submit button
                        Button(action: submit) {
                            HStack {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                }
                                Text("Submit Report")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                (selectedCode.isEmpty || waitMinutes.isEmpty)
                                    ? Color.gray
                                    : Color.orange
                            )
                            .cornerRadius(14)
                        }
                        .disabled(selectedCode.isEmpty || waitMinutes.isEmpty || isSubmitting)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Report Submitted!", isPresented: $showSuccess) {
                Button("OK") {
                    selectedCode = ""
                    waitMinutes = ""
                    searchText = ""
                }
            } message: {
                Text("Thank you! Your report helps fellow travelers plan their trip.")
            }
        }
    }

    private func submit() {
        guard let minutes = Int(waitMinutes), minutes >= 0, minutes <= 600 else {
            errorMessage = "Enter a valid time (0-600 min)"
            return
        }
        guard !selectedCode.isEmpty else {
            errorMessage = "Select an airport"
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await APIService.shared.reportWaitTime(code: selectedCode, minutes: minutes)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
