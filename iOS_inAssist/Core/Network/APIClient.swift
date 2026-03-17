import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case missingCode
    case decoding
    case server(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .missingCode: return "Не удалось получить код авторизации"
        case .decoding: return "Ошибка разбора ответа сервера"
        case .server(let message): return message
        case .unknown: return "Неизвестная ошибка"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func fetchAuthURL(completion: @escaping (Result<URL, Error>) -> Void) {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("auth/google/login"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "state", value: APIConfig.redirectURI)
        ]
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                APIClient.handleNetworkError(error)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                AppRouter.showLogin()
                completion(.failure(APIError.server("Unauthorized")))
                return
            }
            guard let data, let self else {
                completion(.failure(APIError.unknown))
                return
            }
            do {
                let response = try self.decoder.decode(GoogleLoginResponse.self, from: data)
                completion(.success(response.authorizationURL))
            } catch {
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    func completeAuth(code: String, redirectURI: String, completion: @escaping (Result<SessionUser, Error>) -> Void) {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("auth/google/callback"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }

        session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                APIClient.handleNetworkError(error)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                AppRouter.showLogin()
                completion(.failure(APIError.server("Unauthorized")))
                return
            }
            guard let data, let self else {
                completion(.failure(APIError.unknown))
                return
            }
            do {
                let response = try self.decoder.decode(GoogleCallbackResponse.self, from: data)
                let user = SessionUser(userID: response.userID, email: response.email, expiresAt: response.expiresAt)
                completion(.success(user))
            } catch {
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    func sendChat(text: String, user: SessionUser, chatId: Int?, completion: @escaping (Result<ChatMessageResponse, Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("chat/message")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ChatMessageRequest(
            text: text,
            userID: user.userID,
            userEmail: user.email,
            calendarID: "primary",
            timezone: TimeZone.current.identifier,
            metadata: [
                "current_time": ISO8601DateFormatter().string(from: Date())
            ],
            chatID: chatId
        )

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                APIClient.handleNetworkError(error)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 {
                    AppRouter.showLogin()
                    completion(.failure(APIError.server("Unauthorized")))
                    return
                }
                if !(200...299).contains(http.statusCode) {
                    completion(.failure(APIError.server(HTTPURLResponse.localizedString(forStatusCode: http.statusCode))))
                    return
                }
            }
            guard let data, let self else {
                completion(.failure(APIError.unknown))
                return
            }
            do {
                let decoded = try self.decoder.decode(ChatMessageResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    func fetchHistory(user: SessionUser, chatId: Int?, completion: @escaping (Result<[ChatHistoryMessage], Error>) -> Void) {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("chat/history"), resolvingAgainstBaseURL: false)
        var items = [URLQueryItem(name: "user_id", value: user.userID)]
        if let chatId {
            items.append(URLQueryItem(name: "chat_id", value: "\(chatId)"))
        }
        components?.queryItems = items
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                APIClient.handleNetworkError(error)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                AppRouter.showLogin()
                completion(.failure(APIError.server("Unauthorized")))
                return
            }
            guard let data else {
                completion(.failure(APIError.unknown))
                return
            }
            do {
                let decoded = try self.decoder.decode(ChatHistoryResponse.self, from: data)
                completion(.success(decoded.messages))
            } catch {
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    func listChats(user: SessionUser, completion: @escaping (Result<[ChatInfo], Error>) -> Void) {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("chat/list"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "user_id", value: user.userID)]
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        session.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                APIClient.handleNetworkError(error)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                AppRouter.showLogin()
                completion(.failure(APIError.server("Unauthorized")))
                return
            }
            guard let data, let self else {
                completion(.failure(APIError.unknown))
                return
            }
            do {
                let decoded = try self.decoder.decode(ChatListResponse.self, from: data)
                completion(.success(decoded.chats))
            } catch {
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    func createChat(user: SessionUser, completion: @escaping (Result<ChatInfo, Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("chat/create")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCreateRequest(userID: user.userID, userEmail: user.email)
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                APIClient.handleNetworkError(error)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 {
                    AppRouter.showLogin()
                    completion(.failure(APIError.server("Unauthorized")))
                    return
                }
                if !(200...299).contains(http.statusCode) {
                    completion(.failure(APIError.server(HTTPURLResponse.localizedString(forStatusCode: http.statusCode))))
                    return
                }
            }
            guard let data, let self else {
                completion(.failure(APIError.unknown))
                return
            }
            do {
                let decoded = try self.decoder.decode(ChatCreateResponse.self, from: data)
                let info = ChatInfo(id: decoded.id, fileKey: decoded.fileKey, createdAt: nil)
                completion(.success(info))
            } catch {
                completion(.failure(APIError.decoding))
            }
        }.resume()
    }

    private static func handleNetworkError(_ error: Error) {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut:
                AppRouter.showNetworkErrorAlert()
            default:
                break
            }
        }
    }
}
