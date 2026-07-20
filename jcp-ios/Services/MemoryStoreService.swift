import Foundation

// Per-stock conversation memory with AI summarization
class MemoryStoreService {
    static let shared = MemoryStoreService()

    private var cache: [String: MemoryEntry] = [:]
    private let queue = DispatchQueue(label: "memory.store", qos: .background)

    struct MemoryEntry: Codable {
        let stockCode: String
        var messages: [PersistedMessage]
        var summary: String
        var keyFacts: [String]
        var lastUpdated: Date
    }

    struct PersistedMessage: Codable {
        let role: String
        let content: String
        let timestamp: Date
    }

    // MARK: - Load/Save

    func loadMemory(for stockCode: String) -> MemoryEntry? {
        if let cached = cache[stockCode] { return cached }
        let url = fileURL(for: stockCode)
        guard let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(MemoryEntry.self, from: data) else { return nil }
        cache[stockCode] = entry
        return entry
    }

    func saveMemory(stockCode: String, messages: [ChatMessage], summary: String) {
        let persisted = messages.map {
            PersistedMessage(role: $0.agentName ?? "Agent", content: $0.content, timestamp: $0.timestamp)
        }
        let entry = MemoryEntry(stockCode: stockCode, messages: persisted, summary: summary, keyFacts: extractKeyFacts(summary: summary), lastUpdated: Date())
        cache[stockCode] = entry
        queue.async {
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: self.fileURL(for: stockCode), options: .atomic)
            }
        }
    }

    func buildContextPrompt(stockCode: String) -> String {
        guard let mem = loadMemory(for: stockCode), mem.messages.count > 0 else { return "" }
        var ctx = "\n\n[Historical Discussion Summary]\n\(mem.summary)\n"
        if !mem.keyFacts.isEmpty {
            ctx += "\nKey Facts from History:\n" + mem.keyFacts.prefix(5).map { "- \($0)" }.joined(separator: "\n")
        }
        return ctx
    }

    // MARK: - Private

    private func fileURL(for stockCode: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Memory")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(stockCode).json")
    }

    private func extractKeyFacts(summary: String) -> [String] {
        // Simple extraction: lines with bullet points or numbered items
        let lines = summary.components(separatedBy: "\n")
        return lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("-") || $0.trimmingCharacters(in: .whitespaces).hasPrefix("1.") }
    }
}