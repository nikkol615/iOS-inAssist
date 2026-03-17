import Foundation

final class SessionStore {
    static let shared = SessionStore()

    private let key = "inassist.session.user"
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    var currentUser: SessionUser? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? decoder.decode(SessionUser.self, from: data)
        }
        set {
            if let value = newValue, let data = try? encoder.encode(value) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    func clear() {
        currentUser = nil
    }
}
