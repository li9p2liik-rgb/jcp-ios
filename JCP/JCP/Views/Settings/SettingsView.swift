import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configService: ConfigService
    @State private var showAddAI = false
    @State private var showAddMCP = false

    var body: some View {
        Form {
            // MARK: - AI Configuration
            Section {
                ForEach(configService.config.aiConfigs) { config in
                    NavigationLink {
                        AIConfigDetailView(aiConfig: config)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(config.name)
                                    .fontWeight(.medium)
                                Text("\(config.provider.displayName) - \(config.modelName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if config.id == configService.config.defaultAIID {
                                Text("默认")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .onDelete { indices in
                    configService.config.aiConfigs.remove(atOffsets: indices)
                }

                Button { showAddAI = true } label: {
                    Label("添加 AI 配置", systemImage: "plus")
                }
            } header: {
                Text("AI 大模型配置")
            } footer: {
                Text("支持 OpenAI、Gemini、Anthropic 及兼容接口（DeepSeek、Kimi、GLM 等）")
            }

            // MARK: - Agent Style
            Section("小韭菜选人风格") {
                Picker("选人风格", selection: $configService.config.agentSelectionStyle) {
                    Text("平衡 (推荐)").tag(AgentSelectionStyle.balanced)
                    Text("保守").tag(AgentSelectionStyle.conservative)
                    Text("激进").tag(AgentSelectionStyle.aggressive)
                }
            }

            // MARK: - Memory
            Section {
                Toggle("启用记忆管理", isOn: $configService.config.memory.enabled)
                if configService.config.memory.enabled {
                    Stepper("最大关键事实: \(configService.config.memory.maxKeyFacts)",
                            value: $configService.config.memory.maxKeyFacts, in: 5...50)
                }
            } header: {
                Text("记忆管理")
            }

            // MARK: - Theme
            Section("主题设置") {
                Picker("主题", selection: $configService.config.theme) {
                    Text("军绿").tag("military")
                    Text("海洋").tag("ocean")
                    Text("紫色").tag("purple")
                    Text("暖橙").tag("orange")
                    Text("暗黑").tag("dark")
                }
                Picker("涨跌颜色", selection: $configService.config.candleColorMode) {
                    Text("红涨绿跌").tag("red-up")
                    Text("绿涨红跌").tag("green-up")
                }
            }

            // MARK: - MCP
            Section {
                ForEach(configService.config.mcpServers) { server in
                    HStack {
                        Text(server.name)
                        Spacer()
                        if server.enabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                Button { showAddMCP = true } label: {
                    Label("添加 MCP 服务", systemImage: "plus")
                }
            } header: {
                Text("MCP 服务器")
            }

            // MARK: - About
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showAddAI) {
            AddAIConfigView { newConfig in
                configService.config.aiConfigs.append(newConfig)
            }
        }
    }
}
