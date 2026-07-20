import Foundation

// MARK: - F10 Overview

struct F10Overview: Codable {
    let code: String
    var updatedAt: String?
    var source: String?
    var company: [String: String]?
    var financials: FinancialStatements?
    var valuation: StockValuation?
    var errors: [String: String]?
}

struct FinancialStatements: Codable {
    var income: [[String: String]]?
    var balance: [[String: String]]?
    var cashflow: [[String: String]]?
}

struct StockValuation: Codable {
    var price: Double?
    var peTtm: Double?
    var pb: Double?
    var totalMarketCap: Double?
    var floatMarketCap: Double?
    var turnoverRate: Double?
    var amplitude: Double?
    var totalShares: Double?
    var floatShares: Double?
}

// MARK: - Telegraph (快讯)

struct Telegraph: Codable, Identifiable, Equatable {
    var id: String { url }
    let time: String
    let content: String
    let url: String
}

// MARK: - Hot Trend

struct HotTrendItem: Codable, Identifiable, Equatable {
    var id: String { title }
    let title: String
    let hotIndex: Int
    let url: String
    let platform: String
}

// MARK: - Stock Peer

struct StockPeer: Codable, Identifiable, Equatable {
    var id: String { symbol }
    let symbol: String
    let name: String
    var market: String?
}

// MARK: - API Error

struct APIError: Codable, Error, LocalizedError {
    let message: String
    let code: Int?

    var errorDescription: String? { message }
}

// MARK: - Stream Event

enum StreamEvent: Codable {
    case content(String)
    case toolCall(name: String, arguments: String)
    case done
    case error(String)
}
