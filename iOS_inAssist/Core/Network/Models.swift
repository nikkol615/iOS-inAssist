import Foundation

enum APIConfig {
    static let baseURL = URL(string: "http://ukwc8cko48o4s4w08co0c448.194.147.95.202.sslip.io")!
    static let redirectScheme = "inassist"
    static var redirectURI: String { "\(redirectScheme)://auth" }
}

struct GoogleLoginResponse: Codable {
    let authorizationURL: URL
    private enum CodingKeys: String, CodingKey {
        case authorizationURL = "authorization_url"
    }
}

struct GoogleCallbackResponse: Codable {
    let userID: String
    let email: String
    let scope: String?
    let expiresAt: Date?
    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email
        case scope
        case expiresAt = "expires_at"
    }
}

struct ChatMessageRequest: Codable {
    let text: String
    let userID: String?
    let userEmail: String?
    let calendarID: String?
    let timezone: String?
    let metadata: [String: String]?
    let chatID: Int?
    private enum CodingKeys: String, CodingKey {
        case text
        case userID = "user_id"
        case userEmail = "user_email"
        case calendarID = "calendar_id"
        case timezone
        case metadata
        case chatID = "chat_id"
    }
}

struct ChatMessageResponse: Codable {
    let eventID: String?
    let htmlLink: URL?
    let calendarID: String?
    let summary: String?
    private enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case htmlLink = "html_link"
        case calendarID = "calendar_id"
        case summary
    }
}

struct SessionUser: Codable {
    let userID: String
    let email: String
    let expiresAt: Date?
}

struct ChatItem {
    enum Sender {
        case user
        case assistant
    }
    let id = UUID()
    let sender: Sender
    let text: String
    let link: URL?
}

struct ChatHistoryMessage: Codable {
    let role: String
    let text: String
    let htmlLink: URL?
    let timestamp: String?
    private enum CodingKeys: String, CodingKey {
        case role
        case text
        case htmlLink = "html_link"
        case timestamp
    }
}

struct ChatHistoryResponse: Codable {
    let messages: [ChatHistoryMessage]
}

struct ChatInfo: Codable {
    let id: Int
    let fileKey: String
    let createdAt: String?
    private enum CodingKeys: String, CodingKey {
        case id
        case fileKey = "file_key"
        case createdAt = "created_at"
    }
}

struct ChatListResponse: Codable {
    let chats: [ChatInfo]
}

struct ChatCreateRequest: Codable {
    let userID: String?
    let userEmail: String?
    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userEmail = "user_email"
    }
}

struct ChatCreateResponse: Codable {
    let id: Int
    let fileKey: String
    private enum CodingKeys: String, CodingKey {
        case id
        case fileKey = "file_key"
    }
}
