import SwiftUI

struct MeetingListView: View {
    @StateObject private var sessionService = SessionService.shared

    var body: some View {
        Group {
            if sessionService.sessions.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.3")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("暂无会议记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("在行情页面选择股票，点击"进入会议室分析"开始")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                List {
                    ForEach(sessionService.sessions) { session in
                        NavigationLink {
                            MeetingRoomView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                HStack {
                                    Text(session.stockName)
                                        .font(.caption)
                                    Text(session.stockSymbol.uppercased())
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(session.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Text("\(session.messages.count) 条消息")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { indices in
                        for i in indices {
                            sessionService.deleteSession(sessionService.sessions[i].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("会议室")
        .toolbar {
            if !sessionService.sessions.isEmpty {
                EditButton()
            }
        }
    }
}
