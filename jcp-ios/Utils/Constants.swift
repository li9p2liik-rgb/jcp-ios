import Foundation

enum Constants {
    // App 信息
    static let appName = "韭菜盘"
    static let appVersion = "0.3.0"
    static let appDescription = "AI 驱动的智能股票分析系统"
    
    // 默认股票代码
    static let defaultWatchlist = ["000001", "600519", "000333", "300750", "601318"]
    
    // 大盘指数代码
    static let marketIndices = [
        ("000001", "上证指数"),
        ("399001", "深证成指"),
        ("399006", "创业板指"),
        ("688888", "科创50")
    ]
    
    // 时间周期
    static let timePeriods = ["1m", "5m", "15m", "30m", "60m", "1d", "1w", "1mo"]
    static let timePeriodLabels = ["1分", "5分", "15分", "30分", "60分", "日线", "周线", "月线"]
    
    // 市场状态
    static let morningOpen = "09:30"
    static let morningClose = "11:30"
    static let afternoonOpen = "13:00"
    static let afternoonClose = "15:00"
    
    // API 端点
    static let sinaFinanceAPI = "https://hq.sinajs.cn/list="
    static let tencentFinanceAPI = "https://qt.gtimg.cn/q="
    
    // 默认 Agent 配置
    static let defaultAgents: [Agent] = [
        Agent(id: "bull-1", name: "牛眼看市", role: .bull, avatar: "chart.line.uptrend.xyaxis", color: "#ef4444", enabled: true),
        Agent(id: "bear-1", name: "风险警钟", role: .bear, avatar: "chart.line.downtrend.xyaxis", color: "#22c55e", enabled: true),
        Agent(id: "quant-1", name: "量化先锋", role: .quant, avatar: "function", color: "#3b82f6", enabled: true),
        Agent(id: "macro-1", name: "宏观视野", role: .macro, avatar: "building.columns", color: "#f59e0b", enabled: true),
        Agent(id: "news-1", name: "情报猎人", role: .news, avatar: "newspaper", color: "#8b5cf6", enabled: true),
    ]
    
    // 热点平台
    static let hotTrendPlatforms: [PlatformInfo] = [
        PlatformInfo(id: "baidu", name: "百度热搜", icon: "magnifyingglass"),
        PlatformInfo(id: "weibo", name: "微博热搜", icon: "message"),
        PlatformInfo(id: "douyin", name: "抖音热榜", icon: "play.rectangle"),
        PlatformInfo(id: "bilibili", name: "B站热榜", icon: "play.tv"),
        PlatformInfo(id: "toutiao", name: "头条热榜", icon: "newspaper"),
        PlatformInfo(id: "zhihu", name: "知乎热榜", icon: "questionmark.circle"),
    ]
}

// MARK: - 颜色扩展
import SwiftUI

extension Color {
    static let jcpGreen = Color(red: 0.13, green: 0.77, blue: 0.39)   // 涨
    static let jcpRed = Color(red: 0.94, green: 0.18, blue: 0.18)     // 跌
    static let jcpBackground = Color(red: 0.11, green: 0.15, blue: 0.21)
    static let jcpCardBackground = Color(red: 0.15, green: 0.20, blue: 0.27)
    static let jcpSurface = Color(red: 0.18, green: 0.24, blue: 0.32)
    static let jcpTextPrimary = Color.white
    static let jcpTextSecondary = Color(red: 0.60, green: 0.66, blue: 0.74)
    static let jcpTextTertiary = Color(red: 0.40, green: 0.46, blue: 0.54)
    static let jcpAccent = Color(red: 0.24, green: 0.51, blue: 0.99)
    static let jcpBorder = Color(red: 0.20, green: 0.26, blue: 0.34)
}

// MARK: - 格式化工具
extension Double {
    func formatPrice() -> String {
        if self >= 10000 { return String(format: "%.2f", self) }
        if self >= 1000 { return String(format: "%.2f", self) }
        return String(format: "%.2f", self)
    }
    
    func formatPercent() -> String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", self))%"
    }
    
    func formatChange() -> String {
        let sign = self >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", self))"
    }
    
    func formatAmount() -> String {
        if abs(self) >= 1_0000_0000 {
            return String(format: "%.2f亿", self / 1_0000_0000)
        } else if abs(self) >= 1_0000 {
            return String(format: "%.2f万", self / 1_0000)
        }
        return String(format: "%.2f", self)
    }
    
    func formatVolume() -> String {
        if self >= 1_0000_0000 {
            return String(format: "%.2f亿", self / 1_0000_0000)
        } else if self >= 1_0000 {
            return String(format: "%.2f万", self / 1_0000)
        }
        return String(format: "%.0f", self)
    }
}

extension Int64 {
    func formatVolume() -> String {
        if self >= 1_0000_0000 {
            return String(format: "%.2f亿", Double(self) / 1_0000_0000)
        } else if self >= 1_0000 {
            return String(format: "%.2f万", Double(self) / 1_0000)
        }
        return "\(self)"
    }
}

extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: self)
    }
}
