import Foundation

struct AppUser: Codable {
    let id: String
    let email: String
    let name: String
    let avatarURL: String?
    let isPaid: Bool
    let isEarlyAdopter: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case avatarURL = "avatar_url"
        case isPaid = "is_paid"
        case isEarlyAdopter = "is_early_adopter"
        case createdAt = "created_at"
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: AppUser
    let totalUsers: Int

    enum CodingKeys: String, CodingKey {
        case token, user
        case totalUsers = "total_users"
    }
}

struct UserStatusResponse: Codable {
    let isPaid: Bool
    let isEarlyAdopter: Bool
    let totalUsers: Int

    enum CodingKeys: String, CodingKey {
        case isPaid = "is_paid"
        case isEarlyAdopter = "is_early_adopter"
        case totalUsers = "total_users"
    }
}
