import SwiftUI

struct AgentRoomView: View {
    let stock: Stock
    @StateObject private var viewModel = AgentRoomViewModel()
    @State private var showAgentSelection = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.jcpBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 股票信息头
                stockHeader
                
                // Agent 选择
                agentSelector
                
                // 消息列表
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }
                
                // 输入区
                inputBar
            }
        }
        .navigationTitle("AI 智库分析")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.messages.isEmpty {
                    Button(action: { viewModel.clearMessages() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.jcpTextSecondary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.setStock(stock)
            viewModel.selectedAgents = Constants.defaultAgents.filter { $0.enabled }
        }
        .sheet(isPresented: $showAgentSelection) {
            agentSelectionSheet
        }
    }
    
    private var stockHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                    .foregroundColor(.jcpTextPrimary)
                HStack(spacing: 12) {
                    Text(stock.price.formatPrice())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
                    Text(stock.changePercent.formatPercent())
                        .font(.subheadline)
                        .foregroundColor(stock.changePercent >= 0 ? .jcpRed : .jcpGreen)
                    Text(stock.sector)
                        .font(.caption)
                        .foregroundColor(.jcpTextTertiary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.jcpCardBackground)
    }
    
    private var agentSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableAgents) { agent in
                    let isSelected = viewModel.isAgentSelected(agent)
                    Button(action: { viewModel.toggleAgent(agent) }) {
                        HStack(spacing: 4) {
                            Image(systemName: agent.avatar)
                                .font(.caption)
                            Text(agent.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color(hex: agent.color)?.opacity(0.3) ?? Color.jcpAccent.opacity(0.3) : Color.jcpSurface)
                        .foregroundColor(isSelected ? .jcpTextPrimary : .jcpTextSecondary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: agent.color)?.opacity(0.5) ?? Color.clear, lineWidth: isSelected ? 1 : 0)
                        )
                    }
                }
                
                Button(action: { showAgentSelection = true }) {
                    Text("更多")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.jcpSurface)
                        .foregroundColor(.jcpTextSecondary)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color.jcpBackground)
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        AgentMessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isAnalyzing {
                        HStack {
                            ProgressView()
                                .tint(.jcpAccent)
                            Text("专家分析中... \(Int(viewModel.analysisProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.jcpTextSecondary)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.jcpAccent.opacity(0.5))
            Text("多 Agent 协作分析")
                .font(.headline)
                .foregroundColor(.jcpTextPrimary)
            Text("选择专家团队，输入分析问题\n点击发送开始智能分析")
                .font(.subheadline)
                .foregroundColor(.jcpTextTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.jcpBorder)
            HStack(spacing: 12) {
                TextField("输入分析问题（如：该股值得买入吗？）", text: $viewModel.queryText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.jcpTextPrimary)
                    .font(.subheadline)
                    .focused($isFocused)
                    .onSubmit { startAnalysis() }
                
                Button(action: { startAnalysis() }) {
                    Image(systemName: viewModel.isAnalyzing ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.queryText.isEmpty || viewModel.selectedAgents.isEmpty ? .jcpTextTertiary : .jcpAccent)
                }
                .disabled(viewModel.queryText.isEmpty || viewModel.selectedAgents.isEmpty && !viewModel.isAnalyzing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.jcpCardBackground)
        }
    }
    
    private func startAnalysis() {
        guard !viewModel.queryText.isEmpty, !viewModel.isAnalyzing else {
            if viewModel.isAnalyzing {
                // 取消分析（简化处理）
                viewModel.isAnalyzing = false
            }
            return
        }
        isFocused = false
        viewModel.startAnalysis()
    }
    
    private var agentSelectionSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.availableAgents) { agent in
                    HStack {
                        Image(systemName: agent.avatar)
                            .foregroundColor(Color(hex: agent.color) ?? .jcpAccent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(agent.name)
                                .foregroundColor(.jcpTextPrimary)
                            Text(agent.role.rawValue)
                                .font(.caption)
                                .foregroundColor(.jcpTextSecondary)
                        }
                        Spacer()
                        if viewModel.isAgentSelected(agent) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.jcpAccent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleAgent(agent)
                    }
                    .listRowBackground(Color.jcpCardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.jcpBackground)
            .navigationTitle("选择分析专家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        showAgentSelection = false
                    }
                }
            }
        }
    }
}

// MARK: - Agent 消息气泡
struct AgentMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if message.agentId == "system" || message.agentId == "summary" {
                systemMessage
            } else {
                agentMessage
            }
        }
    }
    
    private var systemMessage: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: message.agentId == "summary" ? "sparkles" : "bell.fill")
                    .foregroundColor(message.agentId == "summary" ? Color.yellow : .jcpAccent)
                Text(message.agentName ?? "")
                    .font(.headline)
                    .foregroundColor(message.agentId == "summary" ? Color.yellow : .jcpAccent)
            }
            
            Text(message.content)
                .font(.subheadline)
                .foregroundColor(.jcpTextPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(message.agentId == "summary" ? Color.yellow.opacity(0.1) : Color.jcpAccent.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var agentMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            // Agent 头像
            VStack(spacing: 4) {
                Image(systemName: message.agentId.contains("bull") ? "chart.line.uptrend.xyaxis" :
                        message.agentId.contains("bear") ? "chart.line.downtrend.xyaxis" :
                        message.agentId.contains("quant") ? "function" :
                        message.agentId.contains("macro") ? "building.columns" : "newspaper")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(agentColor)
                    .cornerRadius(20)
                
                Text(message.agentName ?? "")
                    .font(.system(size: 9))
                    .foregroundColor(agentColor)
            }
            .frame(width: 50)
            
            // 内容
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(message.agentName ?? "")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(agentColor)
                    
                    if message.msgType == .opening {
                        Text("开场")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.jcpAccent.opacity(0.2))
                            .foregroundColor(.jcpAccent)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundColor(.jcpTextTertiary)
                }
                
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.jcpTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        }
        .padding(12)
        .background(Color.jcpCardBackground)
        .cornerRadius(12)
    }
    
    private var agentColor: Color {
        Color(hex: message.role ?? "") ?? .jcpAccent
    }
}

// MARK: - 颜色 Hex 扩展
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
