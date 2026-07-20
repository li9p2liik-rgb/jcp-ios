import SwiftUI

@main
struct JCPApp: App {
    @StateObject private var configService = ConfigService.shared
    @StateObject private var marketService = MarketService.shared
    @StateObject private var agentService = AgentService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configService)
                .environmentObject(marketService)
                .environmentObject(agentService)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    agentService.loadDefaultAgents()
                    Task {
                        await marketService.refreshIndices()
                        await marketService.refreshMarketStatus()
                    }
                }
        }
    }

    private var colorScheme: ColorScheme? {
        switch configService.config.theme {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
}
