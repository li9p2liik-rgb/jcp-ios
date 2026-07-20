import Foundation

/// 新浪财经 API 行情数据源
actor SinaMarketDataProvider: MarketDataProvider {

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 10
        return URLSession(configuration: c)
    }()

    // MARK: - Search

    func searchStocks(query: String) async throws -> [Stock] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "https://suggest3.sinajs.cn/suggest/type=11,12,13,14,15&key=\(encoded)")!
        var req = URLRequest(url: url)
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        let (data, _) = try await session.data(for: req)
        guard let text = String(data: data, encoding: .gb_2312_80)
                ?? String(data: data, encoding: .utf8) else {
            throw APIError(message: "搜索数据解码失败", code: -1)
        }
        return parseSearchResult(text)
    }

    private func parseSearchResult(_ text: String) -> [Stock] {
        // Format: var suggestvalue="symbol1,name1,market1;symbol2,name2,market2;..."
        guard let quoteStart = text.firstIndex(of: "\""),
              let quoteEnd = text.lastIndex(of: "\"") else { return [] }
        let content = String(text[text.index(after: quoteStart)..<quoteEnd])
        let items = content.split(separator: ";")

        return items.compactMap { item -> Stock? in
            let parts = item.split(separator: ",", maxSplits: 3)
            guard parts.count >= 3 else { return nil }
            let code = String(parts[1])
            let name = String(parts[2])
            let market = parts.count > 3 ? String(parts[3]) : ""
            let prefix = market == "11" ? "sh" : "sz"
            let symbol = "\(prefix)\(code)"
            return Stock(
                symbol: symbol, name: name, price: 0, change: 0, changePercent: 0,
                volume: 0, amount: 0, marketCap: "", sector: "",
                open: 0, high: 0, low: 0, preClose: 0
            )
        }
    }

    // MARK: - Realtime Quote

    func fetchRealtime(symbol: String) async throws -> Stock {
        let parts = symbol.components(separatedBy: CharacterSet(charactersIn: "."))
        let code: String
        if parts.count == 2 {
            let mkt = parts[0].lowercased()
            let sym = parts[1]
            code = mkt.hasPrefix("sh") ? "sh\(sym)" : "sz\(sym)"
        } else {
            code = symbol.hasPrefix("6") ? "sh\(symbol)" : "sz\(symbol)"
        }

        let url = URL(string: "https://hq.sinajs.cn/list=\(code)")!
        var req = URLRequest(url: url)
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        let (data, _) = try await session.data(for: req)
        guard let text = String(data: data, encoding: .gb_2312_80)
                ?? String(data: data, encoding: .utf8) else {
            throw APIError(message: "行情解码失败", code: -1)
        }
        return parseRealtime(text, symbol: code)
    }

    private func parseRealtime(_ text: String, symbol: String) -> Stock {
        guard let eqIdx = text.firstIndex(of: "=") else {
            return emptyStock(symbol)
        }
        let content = String(text[text.index(after: eqIdx)...]).trimmingCharacters(in: CharacterSet(charactersIn: "\";\n "))
        let fields = content.split(separator: ",")

        guard fields.count >= 32 else { return emptyStock(symbol) }

        let name = String(fields[0])
        let open = Double(fields[1]) ?? 0
        let preClose = Double(fields[2]) ?? 0
        let price = Double(fields[3]) ?? 0
        let high = Double(fields[4]) ?? 0
        let low = Double(fields[5]) ?? 0
        let volume = Double(fields[8]) ?? 0
        let amount = Double(fields[9]) ?? 0

        let change = price - preClose
        let changePercent = preClose > 0 ? (change / preClose) * 100 : 0

        return Stock(
            symbol: symbol, name: name, price: price,
            change: change, changePercent: changePercent,
            volume: volume, amount: amount,
            marketCap: "", sector: "",
            open: open, high: high, low: low, preClose: preClose
        )
    }

    private func emptyStock(_ symbol: String) -> Stock {
        Stock(symbol: symbol, name: "--", price: 0, change: 0, changePercent: 0,
              volume: 0, amount: 0, marketCap: "", sector: "",
              open: 0, high: 0, low: 0, preClose: 0)
    }

    // MARK: - K-Line

    func fetchKLine(symbol: String, period: TimePeriod, limit: Int) async throws -> [KLineData] {
        let parts = symbol.components(separatedBy: CharacterSet(charactersIn: "."))
        let market: String
        let code: String
        if parts.count == 2 {
            market = parts[0].lowercased().hasPrefix("sh") ? "1" : "0"
            code = parts[1]
        } else {
            market = symbol.hasPrefix("6") ? "1" : "0"
            code = symbol
        }

        let scale: Int
        switch period {
        case .min1: scale = 5
        case .day1: scale = 240
        case .week1: scale = 240
        case .month1: scale = 240
        }

        let url = URL(string: "https://money.finance.sina.com.cn/quotes_service/api/json_v2.php/CN_MarketData.getKLineData?symbol=\(market)\(code)&scale=\(scale)&ma=no&datalen=\(limit)")!
        var req = URLRequest(url: url)
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        let (data, _) = try await session.data(for: req)
        let rawList = try JSONDecoder().decode([KLineRawItem].self, from: data)
        var result = rawList.map { $0.toKLineData() }

        // Aggregation for weekly/monthly
        if period == .week1 {
            result = aggregateWeekly(result)
        } else if period == .month1 {
            result = aggregateMonthly(result)
        }

        // Calculate MA
        result = calculateMA(data: result, periods: [5, 10, 20])
        return result
    }

    // MARK: - Indices

    func fetchIndices() async throws -> [MarketIndex] {
        let codes = ["s_sh000001", "s_sz399001", "s_sz399006"]
        let url = URL(string: "https://hq.sinajs.cn/list=\(codes.joined(separator: ","))")!
        var req = URLRequest(url: url)
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        let (data, _) = try await session.data(for: req)
        guard let text = String(data: data, encoding: .gb_2312_80)
                ?? String(data: data, encoding: .utf8) else {
            throw APIError(message: "指数解码失败", code: -1)
        }
        return parseIndices(text)
    }

    private func parseIndices(_ text: String) -> [MarketIndex] {
        let lines = text.split(separator: "\n")
        return lines.compactMap { line -> MarketIndex? in
            let s = String(line)
            guard let eq = s.firstIndex(of: "=") else { return nil }
            let namePart = String(s[s.startIndex..<eq]).replacingOccurrences(of: "var hq_str_", with: "")
            let content = String(s[s.index(after: eq)...])
                .trimmingCharacters(in: CharacterSet(charactersIn: "\";\n "))
            let fields = content.split(separator: ",")
            guard fields.count >= 5 else { return nil }

            let price = Double(fields[1]) ?? 0
            let change = Double(fields[2]) ?? 0
            let changePercent = Double(fields[3]) ?? 0
            let volume = Double(fields[4]) ?? 0
            let amount = Double(fields[5]) ?? 0

            return MarketIndex(
                code: namePart, name: String(fields[0]),
                price: price, change: change,
                changePercent: changePercent,
                volume: volume, amount: amount
            )
        }
    }

    // MARK: - Market Status

    func fetchMarketStatus() async throws -> MarketStatus {
        // Simplified: assume trading on weekdays 9:30-15:00 CST
        let now = Date()
        let cal = Calendar(identifier: .gregorian)
        let weekday = cal.component(.weekday, from: now)
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let totalMin = hour * 60 + minute

        let isWeekend = weekday == 1 || weekday == 7

        if isWeekend {
            return MarketStatus(status: "closed", statusText: "休市", isTradeDay: false, holidayName: "周末")
        }

        if totalMin < 570 { // before 9:30
            return MarketStatus(status: "pre_market", statusText: "未开盘", isTradeDay: true, holidayName: "")
        } else if totalMin >= 570 && totalMin < 690 { // 9:30-11:30
            return MarketStatus(status: "trading", statusText: "交易中", isTradeDay: true, holidayName: "")
        } else if totalMin >= 690 && totalMin < 780 { // 11:30-13:00
            return MarketStatus(status: "lunch_break", statusText: "午休", isTradeDay: true, holidayName: "")
        } else if totalMin >= 780 && totalMin < 900 { // 13:00-15:00
            return MarketStatus(status: "trading", statusText: "交易中", isTradeDay: true, holidayName: "")
        } else {
            return MarketStatus(status: "closed", statusText: "已收盘", isTradeDay: true, holidayName: "")
        }
    }

    // MARK: - Order Book

    func fetchOrderBook(symbol: String) async throws -> OrderBook {
        // Simplified stub — real implementation would use a market data provider
        return OrderBook(bids: [], asks: [])
    }

    // MARK: - Helpers

    private func calculateMA(data: [KLineData], periods: [Int]) -> [KLineData] {
        var result = data
        for i in 0..<result.count {
            for p in periods where i >= p - 1 {
                let sum = result[(i - p + 1)...i].reduce(0) { $0 + $1.close }
                let ma = sum / Double(p)
                switch p {
                case 5: result[i].ma5 = ma
                case 10: result[i].ma10 = ma
                case 20: result[i].ma20 = ma
                default: break
                }
            }
        }
        return result
    }

    private func aggregateWeekly(_ data: [KLineData]) -> [KLineData] {
        guard !data.isEmpty else { return [] }
        var result: [KLineData] = []
        var currentWeek: [KLineData] = []
        let cal = Calendar(identifier: .gregorian)
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]

        for item in data {
            guard let date = fmt.date(from: "\(item.time)T00:00:00Z") else {
                currentWeek.append(item)
                continue
            }
            let w = cal.component(.weekOfYear, from: date)
            if let last = currentWeek.last,
               let lastDate = fmt.date(from: "\(last.time)T00:00:00Z"),
               cal.component(.weekOfYear, from: lastDate) != w {
                result.append(mergeCandles(currentWeek))
                currentWeek = []
            }
            currentWeek.append(item)
        }
        if !currentWeek.isEmpty { result.append(mergeCandles(currentWeek)) }
        return result
    }

    private func aggregateMonthly(_ data: [KLineData]) -> [KLineData] {
        guard !data.isEmpty else { return [] }
        var result: [KLineData] = []
        var currentMonth: [KLineData] = []
        let cal = Calendar(identifier: .gregorian)
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]

        for item in data {
            guard let date = fmt.date(from: "\(item.time)T00:00:00Z") else {
                currentMonth.append(item)
                continue
            }
            let m = cal.component(.month, from: date)
            if let last = currentMonth.last,
               let lastDate = fmt.date(from: "\(last.time)T00:00:00Z"),
               cal.component(.month, from: lastDate) != m {
                result.append(mergeCandles(currentMonth))
                currentMonth = []
            }
            currentMonth.append(item)
        }
        if !currentMonth.isEmpty { result.append(mergeCandles(currentMonth)) }
        return result
    }

    private func mergeCandles(_ candles: [KLineData]) -> KLineData {
        guard let first = candles.first else { fatalError() }
        let open = first.open
        let close = candles.last!.close
        let high = candles.map(\.high).max() ?? open
        let low = candles.map(\.low).min() ?? open
        let volume = candles.reduce(0) { $0 + $1.volume }
        return KLineData(time: first.time, open: open, high: high, low: low, close: close, volume: volume)
    }
}

// MARK: - Raw K-Line JSON item

private struct KLineRawItem: Codable {
    let day: String
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String

    func toKLineData() -> KLineData {
        KLineData(
            time: day,
            open: Double(open) ?? 0,
            high: Double(high) ?? 0,
            low: Double(low) ?? 0,
            close: Double(close) ?? 0,
            volume: Double(volume) ?? 0
        )
    }
}
