import SwiftUI

struct MeetingRoomView: View {
    let stock: Stock

    @StateObject private var meetingService = MeetingService.shared
    @StateObject private var sessionService = SessionService.shared
    @State private var messages: [ChatMessage] = []
    @State private var userInput = ""
    @State private var sessionID: String?
    @FocusState private var inputFocused: Bool

    init(stock: Stock) {
        self.stock = stock
    }

    init(session: ChatSession) {
        self.stock = Stock(
            symbol: session.stockSymbol,
            name: session.stockName,
            price: 0, change: 0, changePercent: 0,
            volume: 0, amount: 0,
            marketCap: "", sector: "",
            open: 0, high: 0, low: 0, preClose: 0
        )
        _messages = State(initialValue: session.messages)
        _sessionID = State(initialValue: session.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stock info header
            stockInfoBar

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { msg in
                            messageBubble(msg)
                        }
                        if meetingService.isRunning {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(meetingService.statusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation { proxy.scrollTo("bottom") }
                }
            }

            Divider()

            // Input area
            inputBar
        }
        .navigationTitle("会议室")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sessionID == nil {
                let session = sessionService.createSession(
                    stockSymbol: stock.symbol,
                    stockName: stock.name,
                    title: "\(stock.name)分析"
                )
                sessionID = session.id
            }
        }
    }

    // MARK: - Stock Info Bar

    private var stockInfoBar: some View {
        HStack {
            Text(stock.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(stock.symbol.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            if stock.price > 0 {
                Text(String(format: "%.2f", stock.price))
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    // MARK: - Message Bubble

    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isModerator = msg.agentId == "moderator"
        let isSummary = msg.msgType == .summary

        return HStack(alignment: .top, spacing: 8) {
            // Avatar
            Text(agentAvatar(for: msg.agentId))
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isModerator ? Color.orange.opacity(0.2) : Color.blue.opacity(0.1))
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text(msg.agentName ?? msg.agentId)
                        .font(.caption)
                        .fontWeight(.semibold)
                    if let role = msg.role {
                        Text(role)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let round = msg.round {
                        Text("第\(round)轮")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(msg.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Content
                Text(LocalizedStringKey(msg.content))
                    .font(.subheadline)
                    .padding(10)
                    .background(
                        isSummary
                            ? Color.orange.opacity(0.08)
                            : Color(.systemGray6)
                    )
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("向小韭菜提问...", text: $userInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3)
                .focused($inputFocused)

            Button {
                submitQuery()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(userInput.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
            }
            .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || meetingService.isRunning)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func submitQuery() {
        let query = userInput.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty, !meetingService.isRunning else { return }
        userInput = ""
        inputFocused = false

        // Add user message
        let userMsg = ChatMessage(
            agentId: "user",
            agentName: "老韭菜",
            role: "投资者",
            content: query
        )
        messages.append(userMsg)

        guard let sid = sessionID else { return }
        sessionService.addMessage(to: sid, message: userMsg)

        // Run meeting
        Task {
            do {
                try await meetingService.runMeeting(
                    stock: stock,
                    userQuery: query
                ) { msg in
                    messages.append(msg)
                    sessionService.addMessage(to: sid, message: msg)
                }
            } catch {
                let errMsg = ChatMessage(
                    agentId: "system",
                    agentName: "系统",
                    content: "出错了：\(error.localizedDescription)"
                )
                messages.append(errMsg)
                if let sid = sessionID {
                    sessionService.addMessage(to: sid, message: errMsg)
                }
            }
        }
    }

    private func agentAvatar(for agentId: String) -> String {
        switch agentId {
        case "moderator": return "🤖"
        case "bull": return "🐂"
        case "bear": return "🐻"
        case "quant": return "📊"
        case "macro": return "🌍"
        case "news": return "📡"
        default: return "👤"
        }
    }
}
