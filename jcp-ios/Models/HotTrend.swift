import Foundation

// MARK: - 热点舆情模型
struct HotTrendItem: Identifiable, Codable {
    let id: String
    let title: String
    let hot: Int
    let url: String?
    let rank: Int
}

struct HotTrendResult: Identifiable, Codable {
    let platform: String
    let platformName: String
    var items: [HotTrendItem]
    var error: String?
    var lastUpdated: Date?
    
    var id: String { platform }
}

struct PlatformInfo: Codable {
    let id: String
    let name: String
    let icon: String
}

// MARK: - 龙虎榜模型
struct LongHuBangItem: Identifiable, Codable {
    let symbol: String
    let name: String
    let typeName: String
    let reason: String
    let totalBuy: Double
    let totalSell: Double
    let netAmount: Double
    
    var id: String { "\(symbol)-\(typeName)" }
}

struct LongHuBangDetail: Identifiable, Codable {
    let businessDept: String
    let buyAmount: Double
    let sellAmount: Double
    let netAmount: Double
    
    var id: String { businessDept }
}

struct LongHuBangListResult: Codable {
    let items: [LongHuBangItem]
    let total: Int
    let page: Int
    let pageSize: Int
}

// MARK: - F10 数据结构
struct F10Company: Codable {
    let name: String
    let englishName: String?
    let listingDate: String?
    let legalRepresentative: String?
    let registeredCapital: String?
    let employees: Int?
    let businessScope: String?
    let industry: String?
    let website: String?
    let address: String?
}

struct F10FinancialData: Codable {
    let year: String
    let revenue: Double?
    let netProfit: Double?
    let eps: Double?
    let bvps: Double?
    let roe: Double?
    let grossMargin: Double?
}

struct F10MainIndicator: Codable {
    let name: String
    let value: String
    let change: String?
}

struct F10Overview: Codable {
    let code: String
    let company: F10Company?
    var valuation: StockValuation?
    let mainIndicators: [F10MainIndicator]?
    let financials: [F10FinancialData]?
    let errors: [String: String]?
}

// MARK: - AI 配置
struct AIConfig: Identifiable, Codable {
    let id: String
    var name: String
    var provider: String
    var apiKey: String
    var baseURL: String
    var modelName: String
    var isDefault: Bool
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double

    enum CodingKeys: String, CodingKey {
        case id, name, provider, apiKey, baseURL, modelName, isDefault
        case temperature, maxTokens, topP, frequencyPenalty, presencePenalty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        provider = try c.decode(String.self, forKey: .provider)
        apiKey = try c.decode(String.self, forKey: .apiKey)
        baseURL = try c.decode(String.self, forKey: .baseURL)
        modelName = try c.decode(String.self, forKey: .modelName)
        isDefault = try c.decode(Bool.self, forKey: .isDefault)
        temperature = try c.decodeIfPresent(Double.self, forKey: .temperature) ?? 0.7
        maxTokens = try c.decodeIfPresent(Int.self, forKey: .maxTokens) ?? 2000
        topP = try c.decodeIfPresent(Double.self, forKey: .topP) ?? 1.0
        frequencyPenalty = try c.decodeIfPresent(Double.self, forKey: .frequencyPenalty) ?? 0
        presencePenalty = try c.decodeIfPresent(Double.self, forKey: .presencePenalty) ?? 0
    }

    init(id: String, name: String, provider: String, apiKey: String, baseURL: String, modelName: String, isDefault: Bool, temperature: Double = 0.7, maxTokens: Int = 2000, topP: Double = 1.0, frequencyPenalty: Double = 0, presencePenalty: Double = 0) {
        self.id = id
        self.name = name
        self.provider = provider
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.modelName = modelName
        self.isDefault = isDefault
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
    }
}

struct AppConfig: Codable {
    var aiConfigs: [AIConfig]
    var defaultAIId: String
    var theme: String
    var watchlist: [String]
}
