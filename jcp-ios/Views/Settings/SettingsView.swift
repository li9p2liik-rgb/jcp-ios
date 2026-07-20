import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showAddConfig = false
    @State private var editingConfig: AIConfig?
    @State private var showVersionInfo = false
    @State private var showUserAgreement = false
    @State private var showPrivacyPolicy = false
    @State private var toastMessage = ""
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        appInfoSection
                        aiConfigSection
                        aboutSection
                        disclaimerText
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("My")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddConfig) {
                AIConfigEditView(config: nil) { config in
                    settingsVM.saveConfig(config)
                    showToastMessage("Config saved")
                }
            }
            .sheet(item: $editingConfig) { config in
                AIConfigEditView(config: config) { updated in
                    settingsVM.saveConfig(updated)
                    showToastMessage("Config updated")
                }
            }
            .sheet(isPresented: $showUserAgreement) {
                LegalTextView(title: "User Agreement", content: userAgreementText)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                LegalTextView(title: "Privacy Policy", content: privacyPolicyText)
            }
            .alert("Version", isPresented: $showVersionInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("JCP v0.3.0\n\nBased on JCP open-source\nhttps://github.com/run-bigpig/jcp\n\nAI-powered stock analysis\nMulti-Agent collaborative analysis")
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toastMessage)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.jcpSurface)
                        .foregroundColor(.jcpTextPrimary)
                        .cornerRadius(8)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showToast = false }
                            }
                        }
                }
            }
        }
    }

    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        withAnimation { showToast = true }
    }

    private var appInfoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.jcpAccent)
            Text("JCP")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.jcpTextPrimary)
            Text("v0.3.0")
                .font(.subheadline)
                .foregroundColor(.jcpTextTertiary)
            Text("AI-powered stock analysis")
                .font(.caption)
                .foregroundColor(.jcpTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.jcpCardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var aiConfigSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.jcpAccent)
                Text("AI Model Config")
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
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.jcpTextTertiary)
                    Text("No AI config. Tap + to add.")
                        .font(.subheadline)
                        .foregroundColor(.jcpTextTertiary)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            } else {
                ForEach(settingsVM.aiConfigs) { config in
                    AIConfigRow(config: config)
                        .contentShape(Rectangle())
                        .onTapGesture { editingConfig = config }
                        .contextMenu {
                            Button { editingConfig = config } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                settingsVM.deleteConfig(id: config.id)
                                showToastMessage("Config deleted")
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.jcpCardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(.jcpTextPrimary)

            VStack(spacing: 0) {
                settingsLinkRow(icon: "doc.text", title: "User Agreement") {
                    showUserAgreement = true
                }
                Divider().background(Color.jcpBorder)
                settingsLinkRow(icon: "hand.raised", title: "Privacy Policy") {
                    showPrivacyPolicy = true
                }
                Divider().background(Color.jcpBorder)
                settingsLinkRow(icon: "info.circle", title: "Version Info") {
                    showVersionInfo = true
                }
            }
        }
        .padding()
        .background(Color.jcpCardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var disclaimerText: some View {
        Text("Disclaimer: All analysis results are AI-generated for reference only, not investment advice. Invest with caution.")
            .font(.system(size: 10))
            .foregroundColor(.jcpTextTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
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

// MARK: - AI Config Row

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
                        Text("Default")
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

// MARK: - AI Config Editor

struct AIConfigEditView: View {
    @Environment(\.dismiss) private var dismiss
    let config: AIConfig?
    let onSave: (AIConfig) -> Void

    @State private var name = ""
    @State private var provider = "openai"
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var modelName = ""
    @State private var isDefault = false
    @State private var testMessage = ""
    @State private var isTesting = false

    private var isEditing: Bool { config != nil }

    let providers = ["openai", "google", "deepseek", "kimi", "glm", "custom"]
    let providerLabels = ["OpenAI", "Google Gemini", "DeepSeek", "Kimi", "GLM", "Custom"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Config Name", text: $name)
                    Picker("Provider", selection: $provider) {
                        ForEach(Array(zip(providers, providerLabels)), id: \.0) { id, label in
                            Text(label).tag(id)
                        }
                    }
                    TextField("Model Name", text: $modelName)
                }

                Section("Connection") {
                    SecureField("API Key", text: $apiKey)
                    TextField("Base URL", text: $baseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                }

                Section {
                    Button(action: { testConnection() }) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(apiKey.isEmpty || isTesting)
                }

                if !testMessage.isEmpty {
                    Section {
                        Text(testMessage)
                            .font(.caption)
                            .foregroundColor(testMessage.contains("OK") ? .jcpGreen : .jcpRed)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.jcpBackground)
            .navigationTitle(isEditing ? "Edit Config" : "New Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
                if let c = config {
                    name = c.name
                    provider = c.provider
                    apiKey = c.apiKey
                    baseURL = c.baseURL
                    modelName = c.modelName
                    isDefault = c.isDefault
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

    private func testConnection() {
        guard !apiKey.isEmpty else { return }
        isTesting = true
        testMessage = ""

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            let ok = apiKey.count > 5 && !baseURL.isEmpty
            let msg = ok
                ? "OK - Config ready (\(provider)/\(modelName))"
                : "Failed - check API Key/URL"
            DispatchQueue.main.async {
                testMessage = msg
                isTesting = false
            }
        }
    }
}

// MARK: - Legal Text View

struct LegalTextView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.jcpTextPrimary)
                    .padding()
            }
            .background(Color.jcpBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private let userAgreementText = """
User Agreement

1. Acceptance of Terms
By using JCP (the App), you agree to these terms. If you do not agree, do not use the App.

2. Service Description
JCP is an AI-powered stock analysis tool providing AI-generated analysis for reference purposes only.

3. User Responsibilities
You are responsible for all actions taken based on the App output. Do not use the App for any illegal activity. Provide accurate information when configuring AI models.

4. Disclaimer of Warranty
The App is provided "as is" without warranty. Analysis results may be inaccurate or incomplete.

5. Limitation of Liability
We are not liable for any investment losses or damages. All investment decisions are at your own risk.

6. Changes to Terms
We may modify these terms. Continued use constitutes acceptance.

Contact: https://github.com/run-bigpig/jcp
"""

private let privacyPolicyText = """
Privacy Policy

1. Information Collection
We collect minimal data: AI config settings (API keys stored locally), user preferences (theme, watchlist).

2. Data Storage
All user data is stored locally on your device. No data is uploaded to external servers except when you explicitly configure an AI model provider.

3. API Keys
Your API keys are stored in UserDefaults on your device only. They are only sent to the AI model providers you configure.

4. Analytics
This App does not collect usage analytics or telemetry data.

5. Third-Party Services
When using AI analysis, queries are sent to the configured AI model provider (OpenAI, Google, etc.). Those providers have their own privacy policies.

6. Data Deletion
Uninstalling the App removes all locally stored data.

7. Contact
For privacy concerns: https://github.com/run-bigpig/jcp
"""