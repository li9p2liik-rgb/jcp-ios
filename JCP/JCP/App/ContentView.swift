import SwiftUI

struct ContentView: View {
    @EnvironmentObject var marketService: MarketService

    var body: some View {
        TabView {
            NavigationStack {
                MarketTabView()
            }
            .tabItem {
                Label("行情", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                MeetingListView()
            }
            .tabItem {
                Label("会议室", systemImage: "person.3.fill")
            }

            NavigationStack {
                PositionListView()
            }
            .tabItem {
                Label("持仓", systemImage: "briefcase.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape.fill")
            }
        }
        .tint(.red)
    }
}
