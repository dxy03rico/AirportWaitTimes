import Foundation

/// Central API client for the Airport Wait Times backend
final class APIService {
    static let shared = APIService()

    // MARK: - Configuration
    // Change this to your server URL (ngrok URL or production)
    #if DEBUG
    private let baseURL = "https://heide-diotic-universally.ngrok-free.dev"
    #else
    private let baseURL = "https://your-production-url.com"
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }

    // MARK: - Auth token
    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }

    // MARK: - Airport Data
    func fetchAirports() async throws -> AirportsResponse {
        let url = URL(string: "\(baseURL)/api/airports")!
        var request = URLRequest(url: url)
        addAuthHeader(&request)

        // ngrok free tier requires this header
        request.setValue("ngrok-skip-browser-warning", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await session.data(for: request)
        try checkResponse(response)
        return try decoder.decode(AirportsResponse.self, from: data)
    }

    // MARK: - Report Wait Time
    func reportWaitTime(code: String, minutes: Int) async throws {
        let url = URL(string: "\(baseURL)/api/report")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(&request)

        let body: [String: Any] = ["code": code, "wait_minutes": minutes]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        try checkResponse(response)
    }

    // MARK: - Auth
    func authenticateWithGoogle(idToken: String, email: String, name: String, avatarURL: String?) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/api/auth/google")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "id_token": idToken,
            "email": email,
            "name": name,
        ]
        if let avatar = avatarURL {
            body["avatar_url"] = avatar
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try checkResponse(response)

        let authResp = try decoder.decode(AuthResponse.self, from: data)
        self.authToken = authResp.token
        return authResp
    }

    // MARK: - User Status
    func getUserStatus() async throws -> UserStatusResponse {
        let url = URL(string: "\(baseURL)/api/user/status")!
        var request = URLRequest(url: url)
        addAuthHeader(&request)

        let (data, response) = try await session.data(for: request)
        try checkResponse(response)
        return try decoder.decode(UserStatusResponse.self, from: data)
    }

    // MARK: - Claim Early Adopter
    func claimEarlyAdopter() async throws {
        let url = URL(string: "\(baseURL)/api/user/claim-early-adopter")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(&request)

        let (_, response) = try await session.data(for: request)
        try checkResponse(response)
    }

    // MARK: - Verify Purchase
    func verifyPurchase(transactionId: String, productId: String) async throws {
        let url = URL(string: "\(baseURL)/api/user/verify-purchase")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(&request)

        let body: [String: Any] = [
            "transaction_id": transactionId,
            "product_id": productId,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await session.data(for: request)
        try checkResponse(response)
    }

    // MARK: - Helpers
    private func addAuthHeader(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func checkResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error (\(code))"
        }
    }
}
