import SwiftUI

struct PositionListView: View {
    @State private var positions: [StockPosition] = []
    @State private var showAddSheet = false

    var body: some View {
        Group {
            if positions.isEmpty {
                ContentUnavailableView {
                    Label("暂无持仓", systemImage: "briefcase")
                } description: {
                    Text("点击右上角 + 添加持仓")
                }
            } else {
                List {
                    Section {
                        HStack {
                            Text("总资产")
                            Spacer()
                            Text(String(format: "¥%.2f", totalMarketValue))
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text("总盈亏")
                            Spacer()
                            Text(String(format: "%+.2f", totalProfit))
                                .foregroundColor(totalProfit >= 0 ? .red : .green)
                        }
                        HStack {
                            Text("收益率")
                            Spacer()
                            Text(String(format: "%+.2f%%", totalReturnRate))
                                .foregroundColor(totalReturnRate >= 0 ? .red : .green)
                        }
                    }

                    Section("持仓明细") {
                        ForEach($positions, id: \.symbol) { $pos in
                            PositionRow(position: pos)
                        }
                        .onDelete(perform: deletePositions)
                    }
                }
            }
        }
        .navigationTitle("持仓")
        .toolbar {
            Button { showAddSheet = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPositionView { newPos in
                positions.append(newPos)
                save()
            }
        }
        .onAppear(perform: load)
    }

    // MARK: - Computed

    private var totalMarketValue: Double {
        positions.reduce(0) { $0 + $1.marketValue }
    }
    private var totalCost: Double {
        positions.reduce(0) { $0 + Double($1.shares) * $1.costPrice }
    }
    private var totalProfit: Double {
        totalMarketValue - totalCost
    }
    private var totalReturnRate: Double {
        guard totalCost > 0 else { return 0 }
        return totalProfit / totalCost * 100
    }

    // MARK: - Persistence

    private let storageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("positions.json")
    }()

    private func save() {
        guard let data = try? JSONEncoder().encode(positions) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([StockPosition].self, from: data) else { return }
        positions = decoded
    }

    private func deletePositions(at offsets: IndexSet) {
        positions.remove(atOffsets: offsets)
        save()
    }
}

// MARK: - Position Row

struct PositionRow: View {
    let position: StockPosition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(position.name)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "¥%.2f", position.marketValue))
                    .fontWeight(.medium)
            }
            HStack {
                Text("\(position.shares)股")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "成本 ¥%.2f", position.costPrice))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%+.2f%%", position.profitPercent))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(position.profitPercent >= 0 ? .red : .green)
            }
        }
    }
}

// MARK: - Add Position Sheet

struct AddPositionView: View {
    let onAdd: (StockPosition) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var symbol = ""
    @State private var shares = ""
    @State private var costPrice = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("股票名称", text: $name)
                TextField("代码 (如 sh600519)", text: $symbol)
                TextField("持仓数量", text: $shares)
                    .keyboardType(.numberPad)
                TextField("成本价", text: $costPrice)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("添加持仓")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let s = Int(shares),
                              let price = Double(costPrice),
                              !name.isEmpty else { return }
                        onAdd(StockPosition(
                            symbol: symbol.isEmpty ? name : symbol,
                            name: name,
                            shares: s,
                            costPrice: price
                        ))
                        dismiss()
                    }
                }
            }
        }
    }
}
