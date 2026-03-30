import SwiftUI

struct AirportCardView: View {
    let airport: Airport

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

    private var waitText: String {
        if let w = airport.combinedWait ?? airport.modelWait {
            return "\(w) min"
        }
        return "N/A"
    }

    private var waitLabel: String {
        if airport.userReportCount > 0 {
            return "👤 \(airport.userReportCount) report\(airport.userReportCount > 1 ? "s" : "") · \(airport.userAgeLabel ?? "")"
        } else if airport.socialCount > 0 {
            return "📰 \(airport.socialCount) Reddit"
        }
        return "🤖 estimated"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: code + name | wait time
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.code)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    Text(airport.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    Text(airport.city)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "52525b"))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(waitText)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(waitColor)
                    Text(waitLabel)
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            }

            // Busyness bar
            HStack(spacing: 6) {
                Text("Busyness")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(hex: "27272a"))
                            .frame(height: 6)
                        Capsule()
                            .fill(busynessColor)
                            .frame(width: geo.size.width * CGFloat(airport.busynessPct) / 100,
                                   height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(airport.busynessPct)%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, alignment: .trailing)
            }

            // Peak label
            if let peak = airport.peakLabel {
                Text(peak)
                    .font(.system(size: 10))
                    .italic()
                    .foregroundColor(Color(hex: "a1a1aa"))
            }

            // Source pills + badges
            HStack(spacing: 4) {
                ForEach(airport.dataSources, id: \.self) { src in
                    SourcePill(source: src)
                }

                Spacer()

                if airport.ice {
                    Badge(text: "🚨 ICE", style: .ice)
                }
            }

            // Alert text
            if let alert = airport.alert {
                Text(alert)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(hex: "18181b"))
        .overlay(
            Rectangle()
                .fill(airport.ice ? Color.red : (airport.userWait != nil || airport.socialCount > 0) ? Color.orange : Color.clear)
                .frame(width: 4),
            alignment: .leading
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "27272a"), lineWidth: 1)
        )
    }
}

struct SourcePill: View {
    let source: String

    private var config: (text: String, bg: Color, fg: Color) {
        switch source {
        case "user":   return ("👤 User", Color(hex: "14532d"), Color(hex: "86efac"))
        case "reddit": return ("📰 Reddit", Color(hex: "7f1d1d"), Color(hex: "fca5a5"))
        default:       return ("🤖 Model", Color(hex: "1e1b4b"), Color(hex: "a5b4fc"))
        }
    }

    var body: some View {
        Text(config.text)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(config.bg)
            .foregroundColor(config.fg)
            .cornerRadius(4)
    }
}

struct Badge: View {
    let text: String
    let style: BadgeStyle

    enum BadgeStyle {
        case ice, alert, reports, social

        var bg: Color {
            switch self {
            case .ice:     return Color(hex: "450a0a")
            case .alert:   return Color(hex: "451a03")
            case .reports: return Color(hex: "172554")
            case .social:  return Color(hex: "431407")
            }
        }

        var fg: Color {
            switch self {
            case .ice:     return Color(hex: "fca5a5")
            case .alert:   return Color(hex: "fed7aa")
            case .reports: return Color(hex: "93c5fd")
            case .social:  return Color(hex: "fdba74")
            }
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(style.bg)
            .foregroundColor(style.fg)
            .cornerRadius(6)
    }
}
