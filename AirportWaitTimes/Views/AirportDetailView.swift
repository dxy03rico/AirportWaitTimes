import SwiftUI

struct AirportDetailView: View {
    let airport: Airport
    @State private var reportMinutes: String = ""
    @State private var isSubmitting = false
    @State private var submitMessage: String?
    @State private var showSubmitSuccess = false

    private var waitColor: Color {
        guard let wait = airport.combinedWait ?? airport.modelWait else { return .gray }
        if wait >= 90 { return .red }
        if wait >= 45 { return .orange }
        if wait >= 20 { return .yellow }
        return .green
    }

    private var busynessColor: Color {
        let pct = airport.busynessPct
        if pct >= 80 { return .red }
        if pct >= 55 { return .orange }
        if pct >= 30 { return .yellow }
        return .green
    }

    var body: some View {
        ZStack {
            Color(hex: "0a0a0f").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header card
                    headerCard

                    // Wait time card
                    waitTimeCard

                    // Busyness card
                    busynessCard

                    // ICE / Alert section
                    if airport.ice || airport.alert != nil {
                        alertCard
                    }

                    // Reddit posts
                    if !airport.socialPosts.isEmpty {
                        redditCard
                    }

                    // Report section
                    reportCard

                    // Travel tips
                    tipsCard
                }
                .padding()
            }
        }
        .navigationTitle(airport.code)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Report Submitted", isPresented: $showSubmitSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for your report! It helps fellow travelers.")
        }
    }

    // MARK: - Header
    private var headerCard: some View {
        VStack(spacing: 6) {
            Text(airport.code)
                .font(.system(size: 48, weight: .heavy))
                .foregroundColor(.white)
            Text(airport.name)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(airport.city)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(hex: "18181b"))
        .cornerRadius(16)
    }

    // MARK: - Wait Time
    private var waitTimeCard: some View {
        VStack(spacing: 12) {
            Text("CURRENT WAIT TIME")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .tracking(1)

            if let wait = airport.combinedWait ?? airport.modelWait {
                Text("\(wait)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(waitColor)
                + Text(" min")
                    .font(.title2.bold())
                    .foregroundColor(waitColor.opacity(0.7))
            } else {
                Text("No data")
                    .font(.title)
                    .foregroundColor(.gray)
            }

            // Data sources
            HStack(spacing: 8) {
                ForEach(airport.dataSources, id: \.self) { src in
                    SourcePill(source: src)
                }
            }

            // Details
            VStack(spacing: 8) {
                if let uw = airport.userWait {
                    DataRow(icon: "👤", label: "User reports (\(airport.userReportCount))",
                            value: "\(uw) min", valueColor: .green)
                }
                if let sw = airport.socialWait {
                    DataRow(icon: "📰", label: "Reddit (\(airport.socialCount))",
                            value: "\(sw) min", valueColor: .red)
                }
                if let mw = airport.modelWait {
                    DataRow(icon: "🤖", label: "Model estimate",
                            value: "\(mw) min", valueColor: .purple)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(hex: "18181b"))
        .cornerRadius(16)
    }

    // MARK: - Busyness
    private var busynessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BUSYNESS LEVEL")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .tracking(1)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(airport.busynessPct)%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(busynessColor)
                    if let peak = airport.peakLabel {
                        Text(peak)
                            .font(.caption)
                            .italic()
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(hex: "27272a"), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: CGFloat(airport.busynessPct) / 100)
                        .stroke(busynessColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 60, height: 60)
            }

            // Busyness bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "27272a"))
                    Capsule()
                        .fill(busynessColor)
                        .frame(width: geo.size.width * CGFloat(airport.busynessPct) / 100)
                }
            }
            .frame(height: 10)

            // Factors
            if !airport.busynessFactors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(airport.busynessFactors, id: \.self) { factor in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 4, height: 4)
                            Text(factor)
                                .font(.caption)
                                .foregroundColor(Color(hex: "a1a1aa"))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(hex: "18181b"))
        .cornerRadius(16)
    }

    // MARK: - Alert
    private var alertCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if airport.ice {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.red)
                    Text("ICE Deployed at Security")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
            }

            if let alert = airport.alert {
                Text(alert)
                    .font(.caption)
                    .foregroundColor(Color(hex: "fca5a5"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "450a0a").opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "7f1d1d"), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // MARK: - Reddit
    private var redditCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("📰 Reddit Reports")
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
                Spacer()
                Text("Last 6 hours")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            ForEach(Array(airport.socialPosts.enumerated()), id: \.offset) { _, post in
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(post.sourceType == "comment" ? "💬 comment" : "📝 post")
                        Text("·")
                        Text("r/\(post.subreddit)")
                        Text("·")
                        Text("\(post.wait) min")
                            .foregroundColor(.orange)
                        Text("·")
                        Text(post.time)
                    }
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "52525b"))
                }
                .padding(10)
                .background(Color(hex: "1c1c22"))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "18181b"))
        .cornerRadius(16)
    }

    // MARK: - Report
    private var reportCard: some View {
        VStack(spacing: 12) {
            Text("📝 Report Your Wait Time")
                .font(.subheadline.bold())
                .foregroundColor(.white)

            HStack(spacing: 8) {
                Text("Waited")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                TextField("min", text: $reportMinutes)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)

                Text("minutes")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                Button(action: submitReport) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit")
                            .font(.subheadline.bold())
                    }
                }
                .disabled(isSubmitting || reportMinutes.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            if let msg = submitMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(msg.contains("Thank") ? .green : .red)
            }
        }
        .padding(16)
        .background(Color(hex: "18181b"))
        .cornerRadius(16)
    }

    // MARK: - Tips
    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("✈️ Travel Tips")
                .font(.subheadline.bold())
                .foregroundColor(.orange)

            TipRow(text: "Arrive 3-4 hours early for domestic, 4-5 for international")
            TipRow(text: "TSA PreCheck / CLEAR lines may be shorter but not guaranteed")
            TipRow(text: "Remove laptops, liquids — follow 3-1-1 rule")
            TipRow(text: "Carry valid government-issued ID at all times")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "18181b"))
        .cornerRadius(16)
    }

    // MARK: - Actions
    private func submitReport() {
        guard let minutes = Int(reportMinutes), minutes >= 0, minutes <= 600 else {
            submitMessage = "Enter 0-600 minutes"
            return
        }
        isSubmitting = true
        submitMessage = nil

        Task {
            do {
                try await APIService.shared.reportWaitTime(code: airport.code, minutes: minutes)
                reportMinutes = ""
                submitMessage = nil
                showSubmitSuccess = true
            } catch {
                submitMessage = "Failed: \(error.localizedDescription)"
            }
            isSubmitting = false
        }
    }
}

struct DataRow: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(icon)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(valueColor)
        }
    }
}

struct TipRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(Color(hex: "a1a1aa"))
        }
    }
}
