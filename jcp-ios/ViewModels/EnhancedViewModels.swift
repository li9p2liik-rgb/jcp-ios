import Foundation

// Telegraph ViewModel only - SettingsViewModel is in ViewModels.swift

class TelegraphViewModel: ObservableObject {
    @Published var telegraphs: [Telegraph] = []
    @Published var isLoading = false

    func loadTelegraphs() {
        isLoading = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let data = MockDataService.shared.generateTelegraphs()
            DispatchQueue.main.async {
                self?.telegraphs = data
                self?.isLoading = false
            }
        }
    }
}
