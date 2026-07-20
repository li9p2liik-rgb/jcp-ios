import Foundation

/// 会话持久化服务
@MainActor
final class SessionService: ObservableObject {
    static let shared = SessionService()

    @Published var sessions: [ChatSession] = []

    private let storageURL: URL
    private let maxSessions = 50

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = docs.appendingPathComponent("sessions.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    func createSession(stockSymbol: String, stockName: String, title: String) -> ChatSession {
        let session = ChatSession(
            title: title,
            stockSymbol: stockSymbol,
            stockName: stockName,
            messages: []
        )
        sessions.insert(session, at: 0)

        // Trim old sessions
        if sessions.count > maxSessions {
            sessions = Array(sessions.prefix(maxSessions))
        }
        save()
        return session
    }

    func addMessage(to sessionID: String, message: ChatMessage) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[idx].messages.append(message)
        sessions[idx].updatedAt = Date()
        save()
    }

    func deleteSession(_ sessionID: String) {
        sessions.removeAll { $0.id == sessionID }
        save()
    }

    func updateTitle(_ sessionID: String, title: String) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[idx].title = title
        save()
    }
}
