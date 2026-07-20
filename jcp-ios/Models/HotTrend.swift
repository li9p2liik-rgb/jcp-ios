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
    let valuation: StockValuation?
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
}

struct AppConfig: Codable {
    var aiConfigs: [AIConfig]
    var defaultAIId: String
    var theme: String
    var watchlist: [String]
}
