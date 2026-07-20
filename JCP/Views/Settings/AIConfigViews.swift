import SwiftUI

struct AIConfigDetailView: View {
    @EnvironmentObject var configService: ConfigService
    let aiConfig: AIConfig

    var body: some View {
        Form {
            Section("基本信息") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(aiConfig.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("供应商")
                    Spacer()
                    Text(aiConfig.provider.displayName)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("模型")
                    Spacer()
                    Text(aiConfig.modelName)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("设为默认") {
                    configService.config.defaultAIID = aiConfig.id
                }
                .disabled(aiConfig.id == configService.config.defaultAIID)

                Button("删除", role: .destructive) {
                    configService.config.aiConfigs.removeAll { $0.id == aiConfig.id }
                    if configService.config.defaultAIID == aiConfig.id {
                        configService.config.defaultAIID = configService.config.aiConfigs.first?.id ?? ""
                    }
                }
            }
        }
        .navigationTitle(aiConfig.name)
    }
}

// MARK: - Add AI Config Sheet

struct AddAIConfigView: View {
    let onAdd: (AIConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var provider: AIProvider = .openai
    @State private var baseURL = "https://api.openai.com"
    @State private var apiKey = ""
    @State private var modelName = "gpt-4o"
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 4096

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)
                    Picker("供应商", selection: $provider) {
                        ForEach(AIProvider.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                        .onChange(of: provider) { _, newProvider in
                            fillDefaults(for: newProvider)
                        }
                    TextField("API 地址", text: $baseURL)
                        .keyboardType(.URL)
                    SecureField("API Key", text: $apiKey)
                    TextField("模型名称", text: $modelName)
                }

                Section("参数") {
                    HStack {
                        Text("Temperature")
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                        Text(String(format: "%.1f", temperature))
                            .frame(width: 32)
                    }
                    Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 256...128000, step: 256)
                }
            }
            .navigationTitle("添加 AI 配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard !name.isEmpty, !apiKey.isEmpty else { return }
                        onAdd(AIConfig(
                            name: name,
                            provider: provider,
                            baseURL: baseURL,
                            apiKey: apiKey,
                            modelName: modelName,
                            maxTokens: maxTokens,
                            temperature: temperature
                        ))
                        dismiss()
                    }
                    .disabled(name.isEmpty || apiKey.isEmpty)
                }
            }
        }
    }

    private func fillDefaults(for provider: AIProvider) {
        switch provider {
        case .openai:
            baseURL = "https://api.openai.com"
            modelName = "gpt-4o"
        case .gemini:
            baseURL = "https://generativelanguage.googleapis.com"
            modelName = "gemini-2.0-flash"
        case .anthropic:
            baseURL = "https://api.anthropic.com"
            modelName = "claude-3-5-sonnet-20241022"
        case .deepseek:
            baseURL = "https://api.deepseek.com"
            modelName = "deepseek-chat"
        case .kimi:
            baseURL = "https://api.moonshot.cn"
            modelName = "moonshot-v1-8k"
        case .glm:
            baseURL = "https://open.bigmodel.cn/api/paas/v4"
            modelName = "glm-4-flash"
        case .vertexai:
            baseURL = "https://aiplatform.googleapis.com"
            modelName = "gemini-2.0-flash"
        }
    }
}
