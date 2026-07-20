import SwiftUI

/// AI 配置详情页
struct AIConfigDetailView: View {
    @EnvironmentObject var configService: ConfigService
    let aiConfig: AIConfig
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("基本信息") {
                row("名称", aiConfig.name)
                row("供应商", aiConfig.provider.displayName)
                row("模型", aiConfig.modelName)
                row("接口地址", aiConfig.baseURL)
                row("超时", "\(aiConfig.timeout)秒")
            }

            Section("参数") {
                row("Temperature", String(format: "%.1f", aiConfig.temperature))
                row("最大 Token", "\(aiConfig.maxTokens)")
            }

            Section {
                Button {
                    configService.setDefaultAI(id: aiConfig.id)
                } label: {
                    HStack {
                        Spacer()
                        Text(aiConfig.id == configService.config.defaultAIID ? "已是默认配置" : "设为默认")
                        Spacer()
                    }
                }
                .disabled(aiConfig.id == configService.config.defaultAIID)

                Button(role: .destructive) {
                    configService.deleteAIConfig(id: aiConfig.id)
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("删除此配置")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(aiConfig.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - 添加 AI 配置页

struct AddAIConfigView: View {
    let onAdd: (AIConfig) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var provider: AIProvider = .deepseek
    @State private var baseURL = "https://api.deepseek.com"
    @State private var apiKey = ""
    @State private var modelName = "deepseek-chat"
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 4096

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)
                        .textInputAutocapitalization(.never)
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
                        .textInputAutocapitalization(.never)
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                    TextField("模型名称", text: $modelName)
                        .textInputAutocapitalization(.never)
                }

                Section("参数") {
                    VStack {
                        Text("Temperature: \(String(format: "%.1f", temperature))")
                            .font(.subheadline)
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                    }
                    Stepper("最大 Token: \(maxTokens)", value: $maxTokens, in: 256...128000, step: 256)
                }

                Section {
                    Text("API Key 存储在本地设备，不会上传")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加 AI 配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
                    .fontWeight(.bold)
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
            modelName = "claude-sonnet-4-20250514"
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
