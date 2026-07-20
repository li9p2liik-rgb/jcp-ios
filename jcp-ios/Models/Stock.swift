import Foundation

// MARK: - 股票模型
struct Stock: Identifiable, Codable, Equatable {
    let symbol: String
    var name: String
    var price: Double
    var change: Double
    var changePercent: Double
    var volume: Int64
    var amount: Double
    var marketCap: String
    var sector: String
    var open: Double
    var high: Double
    var low: Double
    var preClose: Double
    
    var id: String { symbol }
    
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        lhs.symbol == rhs.symbol
    }
}

// MARK: - 股票持仓
struct StockPosition: Codable {
    var shares: Int64
    var costPrice: Double
}

// MARK: - K线数据
struct KLineData: Identifiable, Codable {
    let time: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64
    var amount: Double?
    var avg: Double?
    var ma5: Double?
    var ma10: Double?
    var ma20: Double?
    
    var id: String { time }
}

// MARK: - 盘口数据
struct OrderBookItem: Identifiable, Codable {
    let price: Double
    let size: Int64
    let total: Int64
    let percent: Double
    
    var id: String { "\(price)-\(size)" }
}

struct OrderBook: Codable {
    let bids: [OrderBookItem]
    let asks: [OrderBookItem]
}

// MARK: - 大盘指数
struct MarketIndex: Identifiable, Codable {
    let code: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int64
    let amount: Double
    
    var id: String { code }
}

// MARK: - 市场状态
enum MarketStatus: String, Codable {
    case trading = "trading"
    case closed = "closed"
    case preMarket = "pre_market"
    case lunchBreak = "lunch_break"
    
    var displayText: String {
        switch self {
        case .trading: return "交易中"
        case .closed: return "已收盘"
        case .preMarket: return "盘前"
        case .lunchBreak: return "午休"
        }
    }
    
    var isTrading: Bool { self == .trading }
}

struct MarketStatusInfo: Codable {
    let status: MarketStatus
    let statusText: String
    let isTradeDay: Bool
    let holidayName: String?
}

// MARK: - 估值数据
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

// MARK: - 行情快讯
struct Telegraph: Identifiable, Codable {
    let time: String
    let content: String
    let url: String
    
    var id: String { time + content.prefix(20) }
}

// MARK: - 板块资金流
struct BoardFundFlow: Identifiable, Codable {
    let boardCode: String
    let boardName: String
    let fundFlow: Double
    let rank: Int
    
    var id: String { boardCode }
}

struct BoardFundFlowList: Codable {
    let category: String
    let items: [BoardFundFlow]
    let total: Int
}

// MARK: - 盘口异动
struct StockMove: Identifiable, Codable {
    let symbol: String
    let name: String
    let moveType: String
    let moveTypeName: String
    let price: Double
    let changePercent: Double
    let time: String
    
    var id: String { "\(symbol)-\(time)-\(moveType)" }
}

struct StockMoveList: Codable {
    let moveType: String
    let items: [StockMove]
    let total: Int
}

// MARK: - 板块龙头
struct BoardLeader: Identifiable, Codable {
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
    
    var id: String { symbol }
}

struct BoardLeaderList: Codable {
    let boardCode: String
    let items: [BoardLeader]
}
