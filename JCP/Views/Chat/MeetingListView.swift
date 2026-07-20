import SwiftUI

struct MeetingListView: View {
    @StateObject private var sessionService = SessionService.shared
    @State private var searchText = ""
    @State private var showNewMeeting = false

    var body: some View {
        Group {
            if sessionService.sessions.isEmpty {
                ContentUnavailableView {
                    Label("暂无会议", systemImage: "person.3")
                } description: {
                    Text("在行情页面选择股票，点击"进入会议室分析"")
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
            EditButton()
        }
    }
}
