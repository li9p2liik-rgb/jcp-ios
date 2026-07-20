import Foundation
import Combine

// MARK: - AI Agent 服务
// 模拟 AI Agent 的分析响应
class AIAgentService {
    
    static let shared = AIAgentService()
    
    // 模拟 AI Agent 分析响应
    func generateAgentResponse(agent: Agent, stock: Stock, query: String, context: String) -> AnyPublisher<ChatMessage, Never> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 1.0...2.5)) {
                let response = self.generateResponse(for: agent, stock: stock, query: query, context: context)
                let message = ChatMessage(
                    agentId: agent.id,
                    agentName: agent.name,
                    content: response,
                    msgType: .opinion,
                    round: 1
                )
                promise(.success(message))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // 生成摘要
    func generateSummary(messages: [ChatMessage], stock: Stock) -> AnyPublisher<ChatMessage, Never> {
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                let summary = self.buildSummary(messages: messages, stock: stock)
                let message = ChatMessage(
                    agentId: "summary",
                    agentName: "讨论总结",
                    content: summary,
                    msgType: .summary,
                    round: messages.last?.round
                )
                promise(.success(message))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private
    
    private func generateResponse(for agent: Agent, stock: Stock, query: String, context: String) -> String {
        switch agent.role {
        case .bull:
            return generateBullAnalysis(stock: stock, query: query)
        case .bear:
            return generateBearAnalysis(stock: stock, query: query)
        case .quant:
            return generateQuantAnalysis(stock: stock, query: query)
        case .macro:
            return generateMacroAnalysis(stock: stock, query: query)
        case .news:
            return generateNewsAnalysis(stock: stock, query: query)
        }
    }
    
    private func generateBullAnalysis(stock: Stock, query: String) -> String {
        let templates = [
            "## \(stock.name) 多头分析\n\n**看多观点：**\n\n1. **技术面强势突破**：\(stock.name)当前价格\(stock.price)元，涨幅\(stock.changePercent)%表现强劲，短期均线呈多头排列，MACD金叉向上，成交量配合放大，技术面支持继续上攻。\n\n2. **基本面扎实**：公司所处\(stock.sector)行业景气度持续提升，估值处于合理区间，具备较高的安全边际。近期财报显示营收和利润保持稳健增长。\n\n3. **资金面支撑**：北向资金持续流入，主力资金净买入明显，反映机构对该股的看好态度。\n\n**操作建议：** 建议逢低布局，中期持股待涨，目标价可看高至\(String(format: "%.1f", stock.price * 1.15))元。",
            
            "## \(stock.name) 积极看多\n\n**核心逻辑：**\n\n1. **行业龙头地位**：\(stock.name)在\(stock.sector)领域具有显著的竞争优势和品牌溢价，市场份额持续扩大，护城河深厚。\n\n2. **成长性突出**：公司近年来营收复合增长率保持在20%以上，新业务布局有望打开第二增长曲线。\n\n3. **估值修复空间**：当前PE处于历史低位，随着业绩兑现，估值修复行情可期。\n\n**风险提示：** 注意市场系统性回调风险，建议分批建仓。"
        ]
        return templates.randomElement()!
    }
    
    private func generateBearAnalysis(stock: Stock, query: String) -> String {
        let templates = [
            "## \(stock.name) 风险提示\n\n**谨慎看空：**\n\n1. **估值偏高**：当前股价\(stock.price)元已经透支了未来业绩增长预期，PE处于行业高位，缺乏安全边际。\n\n2. **技术面走弱**：虽然短期反弹，但中期均线仍呈空头排列，RSI指标接近超买区域，回调风险加大。\n\n3. **基本面隐忧**：行业竞争加剧，毛利率呈下降趋势，应收账款周转率恶化，现金流状况需要警惕。\n\n**风险警示：** 追高风险较大，建议等待回调后的安全买点。",
            
            "## \(stock.name) 风险预警\n\n**关注风险点：**\n\n1. **政策风险**：\(stock.sector)行业监管政策趋严，可能对公司经营产生不利影响。\n\n2. **资金面压力**：近期解禁压力较大，大股东有减持迹象，融资余额下降显示杠杆资金在撤退。\n\n3. **替代风险**：新技术路线可能颠覆现有业务模式，公司研发投入不足可能错失转型窗口。\n\n**建议：** 控制仓位，设置好止损位，跌破\(String(format: "%.2f", stock.price * 0.95))元建议减仓。"
        ]
        return templates.randomElement()!
    }
    
    private func generateQuantAnalysis(stock: Stock, query: String) -> String {
        "## \(stock.name) 技术量化分析\n\n**技术指标解读：**\n\n| 指标 | 数值 | 信号 |\n|------|------|------|\n| 当前价 | \(stock.price) | - |\n| 涨跌幅 | \(stock.changePercent)% | - |\n| MACD(12,26,9) | DIF: \(String(format: "%.3f", Double.random(in: -0.5...1.0))) | 金叉 ✓ |\n| RSI(14) | \(Int.random(in: 40...70)) | 中性偏多 |\n| KDJ(9,3,3) | K:\(Int.random(in: 40...80)) D:\(Int.random(in: 35...75)) J:\(Int.random(in: 30...95)) | 多头趋势 |\n| BOLL(20,2) | 中轨:\(String(format: "%.2f", stock.price * 0.98)) 上轨:\(String(format: "%.2f", stock.price * 1.05)) 下轨:\(String(format: "%.2f", stock.price * 0.92)) | 中轨上方运行 |\n| 成交量 | \(stock.volume.formatVolume()) | 放量\(["上涨", "下跌"].randomElement()!) |\n\n**量化评分：** \(Int.random(in: 55...85))/100\n\n**策略建议：** 技术面呈现\(["偏多", "震荡偏多", "中性"].randomElement()!)信号，建议\(["短线参与", "波段操作", "持有观望"].randomElement()!)。"
    }
    
    private func generateMacroAnalysis(stock: Stock, query: String) -> String {
        let templates = [
            "## \(stock.name) 宏观视角分析\n\n**宏观环境研判：**\n\n1. **经济周期定位**：当前国内经济处于复苏初期，PMI连续三个月位于荣枯线上方，GDP增速企稳回升，为股市提供了良好的宏观环境。\n\n2. **货币政策**：央行维持稳健偏宽松的货币政策基调，LPR利率保持低位，市场流动性充裕，有利于估值提升。\n\n3. **产业政策**：\(stock.sector)行业受到国家重点扶持，产业政策红利持续释放，\(stock.name)作为行业龙头有望充分受益。\n\n4. **国际环境**：美联储加息周期接近尾声，人民币汇率压力缓解，北向资金回流A股趋势明显。\n\n**结论：** 宏观环境整体利好\(stock.sector)板块，建议关注结构性机会。",
            
            "## 宏观经济对\(stock.name)的影响\n\n**宏观要素分析：**\n\n1. **利率环境**：低利率环境降低了企业融资成本，有利于\(stock.name)的扩张和投资。\n\n2. **通胀预期**：CPI温和上行，PPI降幅收窄，企业盈利有望改善。\n\n3. **财政政策**：积极的财政政策持续发力，基建投资和减税降费为经济增长提供支撑。\n\n4. **汇率因素**：人民币汇率企稳，减少了对进出口企业的不确定性。\n\n**行业配置建议：** 在当前宏观背景下，\(stock.sector)板块具备较好的配置价值。"
        ]
        return templates.randomElement()!
    }
    
    private func generateNewsAnalysis(stock: Stock, query: String) -> String {
        let templates = [
            "## \(stock.name) 消息面情报\n\n**最新动态：**\n\n🔹 **公司公告**：\(stock.name)发布2024年年度业绩预告，预计归母净利润同比增长\(Int.random(in: 10...50))%-\(Int.random(in: 15...60))%，超出市场预期。\n\n🔹 **行业新闻**：\(stock.sector)行业迎来政策利好，工信部发布《\(stock.sector)行业高质量发展行动计划》，明确支持龙头企业做大做强。\n\n🔹 **机构观点**：多家券商发布研报看好\(stock.name)，其中\(["中信证券", "华泰证券", "国泰君安", "海通证券"].randomElement()!)给出「买入」评级，目标价\(String(format: "%.1f", stock.price * Double.random(in: 1.1...1.3)))元。\n\n🔹 **舆情监控**：网络舆情整体\(["偏正面", "正面为主", "中性偏多"].randomElement()!)，市场关注度较高。\n\n**情报汇总：** 消息面整体利好，建议关注后续催化事件。",
            
            "## 市场情报速递\n\n📰 **热点新闻：**\n\n• \(stock.name)新产品线投产，预计新增年收入\(Int.random(in: 10...100))亿元\n• \(stock.sector)板块今日主力资金净流入\(String(format: "%.1f", Double.random(in: 5...50)))亿元\n• 北向资金今日净买入\(stock.name)\(String(format: "%.1f", Double.random(in: 0.5...5)))亿元\n• \(stock.name)获得\(Int.random(in: 1...10))项新专利授权\n\n⚠️ **需关注：** 下周将有\(stock.name)限售股解禁，解禁市值约\(String(format: "%.1f", Double.random(in: 10...100)))亿元。"
        ]
        return templates.randomElement()!
    }
    
    private func buildSummary(messages: [ChatMessage], stock: Stock) -> String {
        """
        ## \(stock.name) 综合讨论总结
        
        ### 核心观点
        
        **看多方**认为：\(stock.name)技术面走势强劲，基本面扎实，行业景气度向好，估值处于合理区间，具备较好的投资价值。建议逢低布局，持股待涨。
        
        **看空方**提示：注意估值偏高、技术面回调风险、行业竞争加剧等潜在风险，建议控制仓位，设好止损。
        
        **技术面**显示：短期均线多头排列，MACD金叉，成交活跃，但RSI接近超买区域，需要注意回调风险。
        
        **宏观面**来看：当前经济复苏态势良好，货币政策宽松，\(stock.name)所处的\(stock.sector)行业政策环境友好。
        
        ### 综合建议
        
        1. **短期操作**：\(["关注技术面回调后的低吸机会", "短期注意回调风险，不宜追高", "短线可逢低参与波段操作"].randomElement()!)
        2. **中期配置**：\(["基本面稳健，适合中长期持有", "等待更好的安全边际买入", "关注行业催化剂的兑现"].randomElement()!)
        3. **风险管理**：建议仓位控制在\(Int.random(in: 10...30))%以内，止损位设在\(String(format: "%.2f", stock.price * 0.93))元附近。
        
        > *以上分析由 AI 生成，仅供参考，不构成投资建议。投资有风险，入市需谨慎。*
        """
    }
}
