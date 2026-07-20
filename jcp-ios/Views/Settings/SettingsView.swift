import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showAddConfig = false
    @State private var editingConfig: AIConfig?
    @State private var showVersionInfo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // App 信息
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.jcpAccent)
                            Text(Constants.appName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.jcpTextPrimary)
                            Text("v\(Constants.appVersion)")
                                .font(.subheadline)
                                .foregroundColor(.jcpTextTertiary)
                            Text(Constants.appDescription)
                                .font(.caption)
                                .foregroundColor(.jcpTextSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.jcpCardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // AI 配置
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.jcpAccent)
                                Text("AI 模型配置")
                                    .font(.headline)
                                    .foregroundColor(.jcpTextPrimary)
                                Spacer()
                                Button(action: { showAddConfig = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.jcpAccent)
                                }
                            }
                            .padding(.horizontal)
                            
                            if settingsVM.aiConfigs.isEmpty {
                                Text("暂无 AI 配置，请添加")
                                    .font(.subheadline)
                                    .foregroundColor(.jcpTextTertiary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(settingsVM.aiConfigs) { config in
                                    AIConfigRow(config: config)
                                        .contextMenu {
                                            Button(action: { editingConfig = config }) {
                                                Label("编辑", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                settingsVM.deleteConfig(id: config.id)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.jcpCardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // 关于
                        VStack(alignment: .leading, spacing: 12) {
                            Text("关于")
                                .font(.headline)
                                .foregroundColor(.jcpTextPrimary)
                            
                            VStack(spacing: 0) {
                                settingsLinkRow(icon: "doc.text", title: "用户协议", action: {})
                                Divider().background(Color.jcpBorder)
                                settingsLinkRow(icon: "hand.raised", title: "隐私政策", action: {})
                                Divider().background(Color.jcpBorder)
                                settingsLinkRow(icon: "info.circle", title: "版本信息", action: { showVersionInfo = true })
                            }
                        }
                        .padding()
                        .background(Color.jcpCardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // 免责声明
                        Text("免责声明：本应用提供的所有分析结果由 AI 生成，仅供参考，不构成投资建议。投资有风险，入市需谨慎。")
                            .font(.system(size: 10))
                            .foregroundColor(.jcpTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddConfig) {
                AIConfigEditView(config: nil) { config in
                    settingsVM.saveConfig(config)
                }
            }
            .sheet(item: $editingConfig) { config in
                AIConfigEditView(config: config) { updatedConfig in
                    settingsVM.saveConfig(updatedConfig)
                }
            }
            .alert("版本信息", isPresented: $showVersionInfo) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("\(Constants.appName) v\(Constants.appVersion)\n\n基于 JCP (韭菜盘) 开源项目\nhttps://github.com/run-bigpig/jcp\n\nAI 驱动的智能股票分析系统\n多 Agent 协作分析投资决策")
            }
        }
    }
    
    private func settingsLinkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.jcpAccent)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(.jcpTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.jcpTextTertiary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct AIConfigRow: View {
    let config: AIConfig
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle.magnifyingglass")
                .foregroundColor(.jcpAccent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(config.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.jcpTextPrimary)
                    if config.isDefault {
                        Text("默认")
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.jcpAccent.opacity(0.2))
                            .foregroundColor(.jcpAccent)
                            .cornerRadius(4)
                    }
                }
                Text(config.modelName)
                    .font(.caption)
                    .foregroundColor(.jcpTextSecondary)
                Text(config.baseURL)
                    .font(.system(size: 9))
                    .foregroundColor(.jcpTextTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Circle()
                .fill(config.apiKey.isEmpty ? Color.red : Color.jcpGreen)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct AIConfigEditView: View {
    @Environment(\.dismiss) private var dismiss
    let config: AIConfig?
    let onSave: (AIConfig) -> Void
    
    @State private var name: String = ""
    @State private var provider: String = "openai"
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var modelName: String = ""
    @State private var isDefault: Bool = false
    
    private var isEditing: Bool { config != nil }
    
    let providers = ["openai", "google", "deepseek", "kimi", "glm", "custom"]
    let providerLabels = ["OpenAI", "Google Gemini", "DeepSeek", "Kimi", "GLM", "自定义"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)
                    Picker("服务商", selection: $provider) {
                        ForEach(Array(zip(providers, providerLabels)), id: \.0) { id, label in
                            Text(label).tag(id)
                        }
                    }
                    TextField("模型名称", text: $modelName)
                }
                
                Section("连接信息") {
                    SecureField("API Key", text: $apiKey)
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Toggle("设为默认配置", isOn: $isDefault)
                }
                
                Section {
                    Button("测试连接") {
                        // 模拟测试
                    }
                    .foregroundColor(.jcpAccent)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.jcpBackground)
            .navigationTitle(isEditing ? "编辑配置" : "新增配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newConfig = AIConfig(
                            id: config?.id ?? UUID().uuidString,
                            name: name,
                            provider: provider,
                            apiKey: apiKey,
                            baseURL: baseURL,
                            modelName: modelName,
                            isDefault: isDefault
                        )
                        onSave(newConfig)
                        dismiss()
                    }
                    .disabled(name.isEmpty || apiKey.isEmpty)
                }
            }
            .onAppear {
                if let config = config {
                    name = config.name
                    provider = config.provider
                    apiKey = config.apiKey
                    baseURL = config.baseURL
                    modelName = config.modelName
                    isDefault = config.isDefault
                } else {
                    name = ""
                    provider = "openai"
                    apiKey = ""
                    baseURL = "https://api.openai.com/v1"
                    modelName = "gpt-4o"
                    isDefault = false
                }
            }
        }
    }
}
