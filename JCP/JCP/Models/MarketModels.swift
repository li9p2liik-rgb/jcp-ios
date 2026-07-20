import Foundation

// MARK: - Stock (行情数据)

struct Stock: Codable, Identifiable, Equatable {
    var id: String { symbol }
    let symbol: String
    let name: String
    var price: Double
    var change: Double
    var changePercent: Double
    var volume: Double
    var amount: Double
    var marketCap: String
    var sector: String
    var open: Double
    var high: Double
    var low: Double
    var preClose: Double
}

// MARK: - StockPosition (持仓)

struct StockPosition: Codable, Equatable {
    let symbol: String
    let name: String
    var shares: Int
    var costPrice: Double
    var currentPrice: Double?

    var marketValue: Double {
        Double(shares) * (currentPrice ?? costPrice)
    }
    var profit: Double {
        marketValue - Double(shares) * costPrice
    }
    var profitPercent: Double {
        guard costPrice > 0 else { return 0 }
        return ((currentPrice ?? costPrice) - costPrice) / costPrice * 100
    }
}

// MARK: - KLine (K线数据)

struct KLineData: Codable, Identifiable, Equatable {
    var id: String { time }
    let time: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    var amount: Double?
    var ma5: Double?
    var ma10: Double?
    var ma20: Double?
}

// MARK: - TimePeriod

enum TimePeriod: String, Codable, CaseIterable {
    case min1 = "1m"
    case day1 = "1d"
    case week1 = "1w"
    case month1 = "1mo"

    var displayName: String {
        switch self {
        case .min1: "1分钟"
        case .day1: "日K"
        case .week1: "周K"
        case .month1: "月K"
        }
    }
}

// MARK: - OrderBook (订单簿)

struct OrderBookItem: Codable, Identifiable, Equatable {
    var id: Double { price }
    let price: Double
    let size: Double
    var total: Double
    var percent: Double
}

struct OrderBook: Codable, Equatable {
    var bids: [OrderBookItem]
    var asks: [OrderBookItem]
}

// MARK: - MarketIndex (大盘指数)

struct MarketIndex: Codable, Identifiable, Equatable {
    var id: String { code }
    let code: String
    let name: String
    var price: Double
    var change: Double
    var changePercent: Double
    var volume: Double
    var amount: Double
}

// MARK: - MarketStatus (市场状态)

struct MarketStatus: Codable, Equatable {
    let status: String
    let statusText: String
    let isTradeDay: Bool
    let holidayName: String
}
