import Foundation
import CoreFoundation

// Real-time market data via Sina/Tencent public APIs
class MarketDataService {
    static let shared = MarketDataService()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 8
        c.timeoutIntervalForResource = 15
        return URLSession(configuration: c)
    }()

    // Helper: decode GB18030 response from Sina API
    private static let gbEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))

    // Convert local code to Sina format: 000001 -> sz000001, 600519 -> sh600519
    private func sinaCode(_ code: String) -> String {
        code.hasPrefix("6") ? "sh\(code)" : "sz\(code)"
    }

    // MARK: - Stock Quotes
    func fetchRealTimeData(codes: [String], completion: @escaping ([Stock]) -> Void) {
        if codes.isEmpty { completion([]); return }
        let sinaCodes = codes.map { sinaCode($0) }.joined(separator: ",")
        let urlStr = "https://hq.sinajs.cn/list=\(sinaCodes)"
        guard let url = URL(string: urlStr) else { completion([]); return }

        var req = URLRequest(url: url)
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        session.dataTask(with: req) { data, _, error in
            guard let data = data else {
                DispatchQueue.main.async { completion(codes.compactMap { MockDataService.shared.stockPool[$0] }) }
                return
            }
            let text = String(data: data, encoding: Self.gbEncoding) ?? String(data: data, encoding: .utf8) ?? ""
            var stocks: [Stock] = []
            for code in codes {
                if let stock = self.parseSinaQuote(code: code, text: text) {
                    stocks.append(stock)
                } else if let mock = MockDataService.shared.stockPool[code] {
                    var m = mock
                    let variation = Double.random(in: -0.02...0.02)
                    m.price = m.preClose * (1 + variation)
                    m.change = m.price - m.preClose
                    m.changePercent = (m.change / m.preClose) * 100
                    stocks.append(m)
                }
            }
            DispatchQueue.main.async { completion(stocks) }
        }.resume()
    }

    private func parseSinaQuote(code: String, text: String) -> Stock? {
        let sinaCode = self.sinaCode(code)
        guard let range = text.range(of: "var hq_str_\(sinaCode)=") else { return nil }
        var line = String(text[range.upperBound...])
        if let end = line.firstIndex(of: ";") { line = String(line[..<end]) }
        line = line.replacingOccurrences(of: "\"", with: "")
        let fields = line.components(separatedBy: ",")
        guard fields.count >= 32, let preClose = Double(fields[2]), preClose > 0,
              let price = Double(fields[3]), price > 0,
              let high = Double(fields[4]), let low = Double(fields[5]),
              let open = Double(fields[1]) else { return nil }
        let name = fields[0]
        let change = price - preClose
        let changePercent = (change / preClose) * 100
        let volume = Int64(fields[8]) ?? 0
        let amount = Double(fields[9]) ?? 0
        return Stock(symbol: code, name: name, price: price, change: change, changePercent: changePercent,
                     volume: volume, amount: amount, marketCap: "", sector: "", open: open, high: high, low: low, preClose: preClose)
    }

    // MARK: - Market Indices
    func fetchMarketIndices(completion: @escaping ([MarketIndex]) -> Void) {
        let urlStr = "https://hq.sinajs.cn/list=s_sh000001,s_sz399001,s_sz399006,s_sh000688"
        guard let url = URL(string: urlStr) else { completion(MockDataService.shared.marketIndices); return }
        var req = URLRequest(url: url)
        req.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        session.dataTask(with: req) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { completion(MockDataService.shared.marketIndices) }
                return
            }
            let text = String(data: data, encoding: Self.gbEncoding) ?? String(data: data, encoding: .utf8) ?? ""
            let indexMappings: [(String, String)] = [
                ("s_sh000001", "000001"), ("s_sz399001", "399001"),
                ("s_sz399006", "399006"), ("s_sh000688", "688888")
            ]
            let names = ["000001": "上证指数", "399001": "深证成指", "399006": "创业板指", "688888": "科创50"]
            var indices: [MarketIndex] = []
            for (sinaIdx, code) in indexMappings {
                if let range = text.range(of: "var hq_str_\(sinaIdx)=") {
                    var line = String(text[range.upperBound...])
                    if let end = line.firstIndex(of: ";") { line = String(line[..<end]) }
                    line = line.replacingOccurrences(of: "\"", with: "")
                    let f = line.components(separatedBy: ",")
                    if f.count >= 4, let price = Double(f[1]), let change = Double(f[2]), let chgPct = Double(f[3]) {
                        indices.append(MarketIndex(code: code, name: names[code] ?? code, price: price, change: change, changePercent: chgPct, volume: 0, amount: 0))
                    }
                }
            }
            DispatchQueue.main.async {
                completion(indices.isEmpty ? MockDataService.shared.marketIndices : indices)
            }
        }.resume()
    }

    // MARK: - K-Line Data (Tencent API)
    func fetchKLineData(code: String, period: String, days: Int, completion: @escaping ([KLineData]) -> Void) {
        let qtCode = code.hasPrefix("6") ? "sh\(code)" : "sz\(code)"
        let periodMap = ["1d": "day", "1w": "week", "1mo": "month"]
        let qtPeriod = periodMap[period] ?? "day"
        let count = min(days, 300)
        let urlStr = "http://web.ifzq.gtimg.cn/appstock/app/fqkline/get?param=\(qtCode),\(qtPeriod),,,\(count),qfq"
        guard let url = URL(string: urlStr) else {
            completion(MockDataService.shared.generateKLineData(code: code, period: period, days: days))
            return
        }

        session.dataTask(with: url) { data, _, _ in
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let stockData = d[qtCode] as? [String: Any],
                  let kline = (stockData["\(qtPeriod)"] as? [Any]) ?? (stockData["qfq\(qtPeriod)"] as? [Any]) else {
                DispatchQueue.main.async { completion(MockDataService.shared.generateKLineData(code: code, period: period, days: days)) }
                return
            }
            var results: [KLineData] = []
            for item in kline {
                guard let arr = item as? [Any], arr.count >= 6,
                      let date = arr[0] as? String,
                      let open = Double("\(arr[1])"),
                      let close = Double("\(arr[2])"),
                      let high = Double("\(arr[3])"),
                      let low = Double("\(arr[4])"),
                      let vol = Double("\(arr[5])") else { continue }
                results.append(KLineData(time: date, open: open, high: high, low: low, close: close, volume: Int64(vol), amount: nil))
            }
            for i in 0..<results.count {
                if i >= 4 { results[i].ma5 = (0...4).reduce(0) { $0 + results[i-$1].close } / 5 }
                if i >= 9 { results[i].ma10 = (0...9).reduce(0) { $0 + results[i-$1].close } / 10 }
                if i >= 19 { results[i].ma20 = (0...19).reduce(0) { $0 + results[i-$1].close } / 20 }
            }
            DispatchQueue.main.async {
                completion(results.isEmpty ? MockDataService.shared.generateKLineData(code: code, period: period, days: days) : results)
            }
        }.resume()
    }
}