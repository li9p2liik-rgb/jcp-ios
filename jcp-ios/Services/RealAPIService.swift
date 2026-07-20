import Foundation

// Complete real API service for all JCP data sources
class RealAPIService {
    static let shared = RealAPIService()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 10
        c.timeoutIntervalForResource = 20
        return URLSession(configuration: c)
    }()

    // MARK: - Hot Trends

    struct HotTrendFetchResult {
        let items: [HotTrendItem]
        let fromCache: Bool
    }

    func fetchHotTrend(platform: String, completion: @escaping (HotTrendFetchResult?) -> Void) {
        switch platform {
        case "weibo": fetchWeiboTrends(completion: completion)
        case "baidu": fetchBaiduTrends(completion: completion)
        case "zhihu": fetchZhihuTrends(completion: completion)
        case "bilibili": fetchBilibiliTrends(completion: completion)
        case "douyin": fetchDouyinTrends(completion: completion)
        case "toutiao": fetchToutiaoTrends(completion: completion)
        default: completion(nil)
        }
    }

    private func fetchGenericJSON(urlStr: String, headers: [String: String] = [:], completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlStr) else { completion(nil); return }
        var req = URLRequest(url: url)
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        session.dataTask(with: req) { data, _, _ in completion(data) }.resume()
    }

    // Weibo
    private func fetchWeiboTrends(completion: @escaping (HotTrendFetchResult?) -> Void) {
        let url = "https://weibo.com/ajax/side/hotSearch"
        fetchGenericJSON(urlStr: url, headers: ["Referer": "https://weibo.com/", "Accept": "application/json"]) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let realtime = d["realtime"] as? [[String: Any]] else {
                completion(nil); return
            }
            let items = realtime.prefix(50).enumerated().compactMap { i, item -> HotTrendItem? in
                guard let word = item["word"] as? String, !word.isEmpty else { return nil }
                return HotTrendItem(id: "wb_\(i)", title: word, hot: item["num"] as? Int ?? 0, url: "https://s.weibo.com/weibo?q=\(word)", rank: i+1)
            }
            completion(HotTrendFetchResult(items: items, fromCache: false))
        }
    }

    // Baidu
    private func fetchBaiduTrends(completion: @escaping (HotTrendFetchResult?) -> Void) {
        let url = "https://top.baidu.com/api/board?platform=wise&tab=realtime"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let cards = d["cards"] as? [[String: Any]] else {
                completion(nil); return
            }
            var items: [HotTrendItem] = []
            for card in cards {
                guard let content = card["content"] as? [[String: Any]] else { continue }
                for group in content {
                    guard let items2 = group["content"] as? [[String: Any]] else { continue }
                    for it in items2 {
                        guard let word = it["word"] as? String, !word.isEmpty else { continue }
                        items.append(HotTrendItem(id: "bd_\(items.count)", title: word, hot: it["hotScore"] as? Int ?? 0, url: it["url"] as? String, rank: items.count+1))
                    }
                }
            }
            completion(items.isEmpty ? nil : HotTrendFetchResult(items: items, fromCache: false))
        }
    }

    // Zhihu
    private func fetchZhihuTrends(completion: @escaping (HotTrendFetchResult?) -> Void) {
        let url = "https://www.zhihu.com/api/v3/feed/topstory/hot-list-web?limit=50&desktop=true"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [[String: Any]] else {
                completion(nil); return
            }
            let items = d.enumerated().compactMap { i, item -> HotTrendItem? in
                guard let target = item["target"] as? [String: Any],
                      let title = target["title"] as? String else { return nil }
                return HotTrendItem(id: "zh_\(i)", title: title, hot: target["follower_count"] as? Int ?? 0, url: nil, rank: i+1)
            }
            completion(items.isEmpty ? nil : HotTrendFetchResult(items: items, fromCache: false))
        }
    }

    // Bilibili
    private func fetchBilibiliTrends(completion: @escaping (HotTrendFetchResult?) -> Void) {
        let url = "https://s.search.bilibili.com/main/hotword?limit=50"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let list = json["list"] as? [[String: Any]] else {
                completion(nil); return
            }
            let items = list.enumerated().compactMap { i, item -> HotTrendItem? in
                guard let keyword = item["keyword"] as? String else { return nil }
                return HotTrendItem(id: "bl_\(i)", title: keyword, hot: 0, url: "https://search.bilibili.com/all?keyword=\(keyword)", rank: i+1)
            }
            completion(items.isEmpty ? nil : HotTrendFetchResult(items: items, fromCache: false))
        }
    }

    // Douyin
    private func fetchDouyinTrends(completion: @escaping (HotTrendFetchResult?) -> Void) {
        let url = "https://www.douyin.com/aweme/v1/web/hot/search/list/"
        fetchGenericJSON(urlStr: url, headers: ["Referer": "https://www.douyin.com/"]) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let wordList = d["word_list"] as? [[String: Any]] else {
                completion(nil); return
            }
            let items = wordList.enumerated().compactMap { i, item -> HotTrendItem? in
                guard let word = item["word"] as? String else { return nil }
                return HotTrendItem(id: "dy_\(i)", title: word, hot: item["hot_value"] as? Int ?? 0, url: "https://www.douyin.com/search/\(word)", rank: i+1)
            }
            completion(items.isEmpty ? nil : HotTrendFetchResult(items: items, fromCache: false))
        }
    }

    // Toutiao
    private func fetchToutiaoTrends(completion: @escaping (HotTrendFetchResult?) -> Void) {
        let url = "https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc"
        guard let u = URL(string: url) else { completion(nil); return }
        var req = URLRequest(url: u)
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        session.dataTask(with: req) { data, _, _ in
            guard let data = data, let text = String(data: data, encoding: .utf8),
                  let jsonStart = text.range(of: "{"), let jsonEnd = text.range(of: "}", options: .backwards) else {
                completion(nil); return
            }
            let jsonStr = String(text[jsonStart.lowerBound...jsonEnd.lowerBound])
            guard let js = try? JSONSerialization.jsonObject(with: Data(jsonStr.utf8)) as? [String: Any],
                  let d = js["data"] as? [[String: Any]] else {
                completion(nil); return
            }
            let items = d.prefix(50).enumerated().compactMap { i, item -> HotTrendItem? in
                guard let title = item["Title"] as? String else { return nil }
                return HotTrendItem(id: "tt_\(i)", title: title, hot: item["HotValue"] as? Int ?? 0, url: item["Url"] as? String, rank: i+1)
            }
            completion(items.isEmpty ? nil : HotTrendFetchResult(items: items, fromCache: false))
        }.resume()
    }

    // MARK: - LongHuBang (Dragon-Tiger List)
    func fetchLongHuBang(pageSize: Int, pageNumber: Int, completion: @escaping ([LongHuBangItem]) -> Void) {
        let url = "https://datacenter-web.eastmoney.com/api/data/v1/get?sortColumns=TRADE_DATE,BILLBOARD_NET_AMT&sortTypes=-1,-1&pageSize=\(pageSize)&pageNumber=\(pageNumber)&reportName=RPT_DAILYBILLBOARD_DETAILSNEW&columns=SECURITY_CODE,SECUCODE,SECURITY_NAME_ABBR,TRADE_DATE,EXPLAIN,CLOSE_PRICE,CHANGE_RATE,BILLBOARD_NET_AMT,BILLBOARD_BUY_AMT,BILLBOARD_SELL_AMT&source=WEB&client=WEB"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let items = result["data"] as? [[String: Any]] else {
                completion([]); return
            }
            let list = items.compactMap { item -> LongHuBangItem? in
                guard let symbol = item["SECURITY_CODE"] as? String,
                      let name = item["SECURITY_NAME_ABBR"] as? String else { return nil }
                return LongHuBangItem(
                    symbol: symbol, name: name,
                    typeName: item["EXPLAIN"] as? String ?? "",
                    reason: item["EXPLANATION"] as? String ?? "",
                    totalBuy: (item["BILLBOARD_BUY_AMT"] as? Double) ?? 0,
                    totalSell: (item["BILLBOARD_SELL_AMT"] as? Double) ?? 0,
                    netAmount: (item["BILLBOARD_NET_AMT"] as? Double) ?? 0)
            }
            completion(list)
        }
    }

    // MARK: - Board Fund Flow
    func fetchBoardFundFlow(category: String, completion: @escaping ([BoardFundFlow]) -> Void) {
        let fs = "m:90+t2,m:90+t3"  // main net flow
        let fields = "f2,f3,f4,f12,f14,f62,f184,f66,f69,f72,f75,f78,f81,f84,f87"
        let url = "https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=30&po=1&np=1&fltt=2&invt=2&fid=f62&fs=\(fs)&fields=\(fields.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let list = d["diff"] as? [[String: Any]] else {
                completion([]); return
            }
            let items = list.enumerated().compactMap { i, item -> BoardFundFlow? in
                guard let name = item["f14"] as? String else { return nil }
                return BoardFundFlow(
                    boardCode: item["f12"] as? String ?? "",
                    boardName: name,
                    fundFlow: (item["f62"] as? Double) ?? 0,
                    rank: i + 1)
            }
            completion(items)
        }
    }

    // MARK: - Market Moves
    func fetchStockMoves(moveType: String, completion: @escaping ([StockMove]) -> Void) {
        // Eastmoney abnormal move API
        let url = "https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=30&np=1&fltt=2&invt=2&fid=f3&fs=b:DLMJ0101&fields=f2,f3,f12,f14,f8"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let list = d["diff"] as? [[String: Any]] else {
                completion([]); return
            }
            let now = Date()
            let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
            let timeStr = fmt.string(from: now)
            let moves = list.compactMap { item -> StockMove? in
                guard let name = item["f14"] as? String else { return nil }
                return StockMove(
                    symbol: item["f12"] as? String ?? "",
                    name: name,
                    moveType: "abnormal",
                    moveTypeName: "Abnormal Move",
                    price: (item["f2"] as? Double) ?? 0,
                    changePercent: (item["f3"] as? Double) ?? 0,
                    time: timeStr)
            }
            completion(moves)
        }
    }

    // MARK: - Order Book (Real 5-level)
    func fetchOrderBook(code: String, completion: @escaping (OrderBook?) -> Void) {
        let qtCode = code.hasPrefix("6") ? "1.\(code)" : "0.\(code)"
        let url = "https://push2.eastmoney.com/api/qt/stock/get?secid=\(qtCode)&fields=f43,f44,f45,f46,f47,f48,f19,f20,f21,f22,f23,f24,f25,f26,f27,f28,f29,f30,f31,f32,f33,f34,f35,f36,f37,f38,f39,f40,f41,f42"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any] else {
                completion(nil); return
            }
            var bids: [OrderBookItem] = []
            var asks: [OrderBookItem] = []
            var bidTotal: Int64 = 0
            var askTotal: Int64 = 0
            // Buy levels: f19-f28 (price), f20-f29 (volume)
            let buyPrices: [String] = ["f19","f21","f23","f25","f27"]
            let buyVols: [String]   = ["f20","f22","f24","f26","f28"]
            let sellPrices: [String] = ["f39","f37","f35","f33","f31"]
            let sellVols: [String]   = ["f40","f38","f36","f34","f32"]
            for i in 0..<5 {
                if let p = d[buyPrices[i]] as? Double, let v = d[buyVols[i]] as? Double, v > 0 {
                    bidTotal += Int64(v)
                    bids.append(OrderBookItem(price: p, size: Int64(v), total: bidTotal, percent: 0))
                }
                if let p = d[sellPrices[i]] as? Double, let v = d[sellVols[i]] as? Double, v > 0 {
                    askTotal += Int64(v)
                    asks.append(OrderBookItem(price: p, size: Int64(v), total: askTotal, percent: 0))
                }
            }
            let maxTotal = max(bidTotal, askTotal)
            if maxTotal > 0 {
                bids = bids.map { OrderBookItem(price: $0.price, size: $0.size, total: $0.total, percent: Double($0.total)/Double(maxTotal)*100) }
                asks = asks.map { OrderBookItem(price: $0.price, size: $0.size, total: $0.total, percent: Double($0.total)/Double(maxTotal)*100) }
            }
            completion(OrderBook(bids: bids, asks: asks))
        }
    }

    // MARK: - F10 Company Overview
    func fetchF10Overview(code: String, completion: @escaping (F10Overview?) -> Void) {
        let url = "https://emweb.securities.eastmoney.com/PC_HSF10/CompanySurvey/PageAjax?code=\(code)"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let jbzl = json["jbzl"] as? [String: Any] else {
                completion(nil); return
            }
            let company = F10Company(
                name: jbzl["com_name"] as? String ?? "",
                englishName: nil,
                listingDate: jbzl["listing_date"] as? String,
                legalRepresentative: jbzl["legal_representative"] as? String,
                registeredCapital: jbzl["reg_capital"] as? String,
                employees: (jbzl["employees"] as? String).flatMap { Int($0) },
                businessScope: jbzl["business_scope"] as? String,
                industry: jbzl["industry"] as? String,
                website: jbzl["web_site"] as? String,
                address: jbzl["reg_address"] as? String)
            completion(F10Overview(code: code, company: company, valuation: nil, mainIndicators: nil, financials: nil, errors: nil))
        }
    }

    // MARK: - F10 Valuation
    func fetchValuation(code: String, completion: @escaping (StockValuation?) -> Void) {
        let qtCode = code.hasPrefix("6") ? "1.\(code)" : "0.\(code)"
        let url = "https://push2.eastmoney.com/api/qt/stock/get?secid=\(qtCode)&fields=f43,f44,f45,f46,f47,f48,f116,f117,f162,f167,f168,f169,f170"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any] else {
                completion(nil); return
            }
            let val = StockValuation(
                price: d["f43"] as? Double,
                peTtm: d["f162"] as? Double,
                pb: d["f167"] as? Double,
                totalMarketCap: d["f116"] as? Double,
                floatMarketCap: d["f117"] as? Double,
                turnoverRate: d["f168"] as? Double,
                amplitude: d["f169"] as? Double,
                totalShares: d["f44"] as? Double,
                floatShares: d["f45"] as? Double)
            completion(val)
        }
    }

    // MARK: - News/Telegraph (CLS)
    func fetchTelegraphs(completion: @escaping ([Telegraph]) -> Void) {
        let url = "https://www.cls.cn/api/telegraph/list?app=cailianpress&os=ios&sv=8.0"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let d = json["data"] as? [String: Any],
                  let list = d["roll_data"] as? [[String: Any]] else {
                completion([]); return
            }
            let items = list.compactMap { item -> Telegraph? in
                guard let title = item["title"] as? String ?? item["brief"] as? String,
                      let ctime = item["ctime"] as? Double else { return nil }
                let d = Date(timeIntervalSince1970: ctime)
                let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
                return Telegraph(time: fmt.string(from: d), content: title, url: item["shareurl"] as? String ?? "")
            }
            completion(items)
        }
    }

    // MARK: - Research Reports
    func fetchResearchReports(code: String, completion: @escaping ([ResearchReport]) -> Void) {
        let url = "https://reportapi.eastmoney.com/report/list?cb=&industryCode=*&pageSize=20&rating=*&ratingChange=*&beginTime=&endTime=&pageNo=1&fields=&qType=0&orgCode=&rcode=\(code)"
        fetchGenericJSON(urlStr: url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let list = json["data"] as? [[String: Any]] else {
                completion([]); return
            }
            let items = list.enumerated().compactMap { i, item -> ResearchReport? in
                return ResearchReport(
                    id: "rr_\(i)",
                    title: item["title"] as? String ?? "",
                    orgName: item["orgName"] as? String ?? "",
                    rating: item["rating"] as? String ?? "",
                    publishDate: item["publishDate"] as? String ?? "",
                    stockCode: code,
                    stockName: "")
            }
            completion(items)
        }
    }
}