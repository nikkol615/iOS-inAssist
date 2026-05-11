import Foundation

enum APIConfig {
    private static let baseURLString = "http://ukwc8cko48o4s4w08co0c448.194.147.95.202.sslip.io"
    static let baseURL: URL = {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid APIConfig baseURL: \(baseURLString)")
        }
        return url
    }()
    // ML-сервис (транскрипция голоса)
    static let mlBaseURLString = "http://qg8gk4gko4sc0wkgw8w4owgo.194.147.95.202.sslip.io"
    static let mlBaseURL: URL = {
        guard let url = URL(string: mlBaseURLString) else {
            fatalError("Invalid APIConfig mlBaseURL: \(mlBaseURLString)")
        }
        return url
    }()
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
    let eventCreated: Bool?
    let chatID: Int?
    let eventStart: String?
    let eventEnd: String?
    let eventLocation: String?
    let eventDescription: String?
    private enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case htmlLink = "html_link"
        case calendarID = "calendar_id"
        case summary
        case eventCreated = "event_created"
        case chatID = "chat_id"
        case eventStart = "event_start"
        case eventEnd = "event_end"
        case eventLocation = "event_location"
        case eventDescription = "event_description"
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
    let eventStart: String?
    let eventEnd: String?
    let eventLocation: String?
    let eventDescription: String?
    let pendingConfirmation: Bool

    init(sender: Sender, text: String, link: URL?,
         eventStart: String? = nil, eventEnd: String? = nil,
         eventLocation: String? = nil, eventDescription: String? = nil,
         pendingConfirmation: Bool = false) {
        self.sender = sender
        self.text = text
        self.link = link
        self.eventStart = eventStart
        self.eventEnd = eventEnd
        self.eventLocation = eventLocation
        self.eventDescription = eventDescription
        self.pendingConfirmation = pendingConfirmation
    }
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
    let status: String?  // "active" | "done" | "cancelled"
    private enum CodingKeys: String, CodingKey {
        case id
        case fileKey = "file_key"
        case createdAt = "created_at"
        case status
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

struct TranscribeResponse: Codable { let text: String }

struct CalendarEventResponse: Codable {
    let id: String?
    let summary: String?
    let start: String?
    let end: String?
    let htmlLink: String?
    let location: String?
    let description: String?
    private enum CodingKeys: String, CodingKey {
        case id, summary, start, end
        case htmlLink = "html_link"
        case location, description
    }
}

struct CalendarEventsListResponse: Codable {
    let items: [CalendarEventResponse]
}
