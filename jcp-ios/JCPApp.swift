import SwiftUI

@main
struct JCPApp: App {
    @StateObject private var watchlistVM = WatchlistViewModel()
    @StateObject private var marketVM = MarketViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(watchlistVM)
                .environmentObject(marketVM)
                .environmentObject(settingsVM)
                .preferredColorScheme(.dark)
        }
    }
}
