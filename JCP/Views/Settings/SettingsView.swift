import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configService: ConfigService
    @State private var showAddAI = false

    var body: some View {
        Form {
            // MARK: - AI 配置
            Section {
                if configService.config.aiConfigs.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("尚未添加 AI 配置")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("点击下方按钮添加 DeepSeek、OpenAI 等")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                } else {
                    ForEach(configService.config.aiConfigs) { cfg in
                        NavigationLink {
                            AIConfigDetailView(aiConfig: cfg)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cfg.name)
                                        .fontWeight(.medium)
                                    Text("\(cfg.provider.displayName) · \(cfg.modelName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if cfg.id == configService.config.defaultAIID {
                                    Text("默认")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .onDelete { idx in
                        for i in idx {
                            configService.deleteAIConfig(id: configService.config.aiConfigs[i].id)
                        }
                    }
                }

                Button { showAddAI = true } label: {
                    Label("添加 AI 配置", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("AI 大模型配置")
            } footer: {
                Text("支持 OpenAI、Gemini、DeepSeek、Kimi、GLM 等")
            }

            // MARK: - 选人风格
            Section {
                Picker("选人风格", selection: Binding(
                    get: { configService.config.agentSelectionStyle },
                    set: { configService.config.agentSelectionStyle = $0; configService.saveToDisk() }
                )) {
                    Text("平衡 (推荐)").tag(AgentSelectionStyle.balanced)
                    Text("保守").tag(AgentSelectionStyle.conservative)
                    Text("激进").tag(AgentSelectionStyle.aggressive)
                }
            } header: {
                Text("小韭菜选人风格")
            } footer: {
                Text("平衡：综合短中线视角；保守：偏风控基本面；激进：偏技术资金面")
            }

            // MARK: - 记忆管理
            Section {
                Toggle("启用记忆管理", isOn: Binding(
                    get: { configService.config.memory.enabled },
                    set: { configService.config.memory.enabled = $0; configService.saveToDisk() }
                ))
                if configService.config.memory.enabled {
                    Stepper(
                        "最大关键事实: \(configService.config.memory.maxKeyFacts)",
                        value: Binding(
                            get: { configService.config.memory.maxKeyFacts },
                            set: { configService.config.memory.maxKeyFacts = $0; configService.saveToDisk() }
                        ),
                        in: 5...50
                    )
                }
            } header: {
                Text("记忆管理")
            } footer: {
                Text("记住历史讨论要点，提升分析连续性")
            }

            // MARK: - 主题
            Section {
                Picker("主题配色", selection: Binding(
                    get: { configService.config.theme },
                    set: { configService.config.theme = $0; configService.saveToDisk() }
                )) {
                    Text("军绿").tag("military")
                    Text("海洋").tag("ocean")
                    Text("紫色").tag("purple")
                    Text("暖橙").tag("orange")
                    Text("暗黑").tag("dark")
                }
                Picker("涨跌颜色", selection: Binding(
                    get: { configService.config.candleColorMode },
                    set: { configService.config.candleColorMode = $0; configService.saveToDisk() }
                )) {
                    Text("红涨绿跌").tag("red-up")
                    Text("绿涨红跌").tag("green-up")
                }
            } header: {
                Text("主题设置")
            }

            // MARK: - MCP
            Section {
                if configService.config.mcpServers.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "server.rack")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("暂无 MCP 服务器")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(configService.config.mcpServers) { server in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(server.name)
                                    .fontWeight(.medium)
                                Text(server.transportType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: server.enabled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(server.enabled ? .green : .secondary)
                        }
                    }
                }
            } header: {
                Text("MCP 服务器")
            } footer: {
                Text("Model Context Protocol 扩展工具能力")
            }

            // MARK: - 关于
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("技术栈")
                    Spacer()
                    Text("SwiftUI · Swift 6")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("关于 JCP AI")
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showAddAI) {
            AddAIConfigView { newConfig in
                configService.addAIConfig(newConfig)
            }
        }
    }
}
