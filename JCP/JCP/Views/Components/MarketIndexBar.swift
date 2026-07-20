import SwiftUI

struct MarketIndexBar: View {
    @EnvironmentObject var marketService: MarketService

    var body: some View {
        if marketService.indices.isEmpty {
            Text("加载指数中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(marketService.indices) { index in
                        indexView(index)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .background(Color(.systemBackground))
        }
    }

    private func indexView(_ index: MarketIndex) -> some View {
        HStack(spacing: 6) {
            Text(index.name)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", index.price))
                .font(.caption)
                .fontWeight(.medium)
            Text(String(format: "%+.2f%%", index.changePercent))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(index.changePercent >= 0 ? .red : .green)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    (index.changePercent >= 0 ? Color.red : Color.green)
                        .opacity(0.1)
                )
                .cornerRadius(3)
        }
    }
}
