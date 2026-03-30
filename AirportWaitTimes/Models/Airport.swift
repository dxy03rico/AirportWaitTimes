import Foundation

struct Airport: Identifiable, Codable {
    let code: String
    let name: String
    let city: String
    let lat: Double
    let lng: Double
    let ice: Bool
    let alert: String?

    // User reports
    let userWait: Int?
    let userReportCount: Int
    let userAgeLabel: String?

    // Social (Reddit)
    let socialWait: Int?
    let socialCount: Int
    let socialPosts: [SocialPost]

    // Busyness model
    let busynessPct: Int
    let modelWait: Int?
    let peakLabel: String?
    let busynessFactors: [String]

    // Combined
    let combinedWait: Int?
    let dataSources: [String]

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code, name, city, lat, lng, ice, alert
        case userWait = "user_wait"
        case userReportCount = "user_report_count"
        case userAgeLabel = "user_age_label"
        case socialWait = "social_wait"
        case socialCount = "social_count"
        case socialPosts = "social_posts"
        case busynessPct = "busyness_pct"
        case modelWait = "model_wait"
        case peakLabel = "peak_label"
        case busynessFactors = "busyness_factors"
        case combinedWait = "combined_wait"
        case dataSources = "data_sources"
    }
}

struct SocialPost: Codable {
    let title: String
    let wait: Int
    let subreddit: String
    let url: String
    let time: String
    let sourceType: String

    enum CodingKeys: String, CodingKey {
        case title, wait, subreddit, url, time
        case sourceType = "source_type"
    }
}

struct AirportsResponse: Codable {
    let airports: [Airport]
    let lastUpdated: String
    let totalUserReports: Int
    let totalSocialReports: Int
    let socialLastFetched: String?
    let notice: String?
    let freshnessWindow: String?

    enum CodingKeys: String, CodingKey {
        case airports
        case lastUpdated = "last_updated"
        case totalUserReports = "total_user_reports"
        case totalSocialReports = "total_social_reports"
        case socialLastFetched = "social_last_fetched"
        case notice
        case freshnessWindow = "freshness_window"
    }
}

struct ReportResponse: Codable {
    let status: String
    let message: String
}
