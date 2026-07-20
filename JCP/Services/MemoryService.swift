import Foundation

/// 记忆管理服务 — 基于关键词匹配的简化记忆召回
@MainActor
final class MemoryService: ObservableObject {
    static let shared = MemoryService()

    @Published var keyFacts: [MemoryFact] = []
    @Published var isEnabled: Bool = true

    private let maxFacts = 20
    private let storageURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL = docs.appendingPathComponent("memory.json")
        load()
    }

    // MARK: - CRUD

    func remember(_ content: String, from agent: String, relatedStock: String? = nil) {
        let sentences = content
            .split(separator: /[。.！!？?\n]/)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 10 }

        for sentence in sentences {
            let fact = MemoryFact(
                content: sentence,
                source: agent,
                stockSymbol: relatedStock,
                timestamp: Date()
            )
            keyFacts.insert(fact, at: 0)
            if keyFacts.count > maxFacts * 2 {
                keyFacts = Array(keyFacts.prefix(maxFacts * 2))
            }
        }
        save()
    }

    /// 召回与查询相关的记忆
    func recall(query: String, limit: Int = 5) -> [MemoryFact] {
        guard isEnabled else { return [] }
        let keywords = extractKeywords(from: query)
        guard !keywords.isEmpty else {
            return Array(keyFacts.prefix(limit))
        }

        // Score each fact by keyword overlap
        let scored = keyFacts.map { fact -> (MemoryFact, Int) in
            let factLower = fact.content.lowercased()
            let score = keywords.reduce(0) { $0 + (factLower.contains($1) ? 1 : 0) }
            return (fact, score)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
        .prefix(limit)

        return scored.map(\.0)
    }

    func clear() {
        keyFacts.removeAll()
        save()
    }

    // MARK: - Private

    private func extractKeywords(from text: String) -> [String] {
        // Chinese: segment by common delimiters, filter short tokens
        let raw = text
            .replacingOccurrences(of: /[，。！？、：；""（）\s]/, with: " ")
            .split(separator: " ")
            .map { String($0).lowercased() }
            .filter { $0.count >= 2 }
        return Array(Set(raw)).prefix(20).map { String($0) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([MemoryFact].self, from: data) else { return }
        keyFacts = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(keyFacts) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

struct MemoryFact: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    let content: String
    let source: String
    let stockSymbol: String?
    let timestamp: Date
}
