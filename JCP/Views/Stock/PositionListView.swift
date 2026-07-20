import SwiftUI

struct PositionListView: View {
    @State private var positions: [StockPosition] = []
    @State private var showAddSheet = false

    private let storageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("positions.json")
    }()

    var body: some View {
        Group {
            if positions.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "briefcase")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("暂无持仓")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("点击右上角 + 添加持仓记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    Section {
                        HStack {
                            Text("总市值")
                            Spacer()
                            Text(String(format: "%.2f", totalMarketValue))
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text("总成本")
                            Spacer()
                            Text(String(format: "%.2f", totalCost))
                        }
                        HStack {
                            Text("总盈亏")
                            Spacer()
                            Text(String(format: "%+.2f", totalProfit))
                                .foregroundColor(totalProfit >= 0 ? .red : .green)
                                .fontWeight(.medium)
                        }
                        HStack {
                            Text("收益率")
                            Spacer()
                            Text(String(format: "%+.2f%%", totalReturnRate))
                                .foregroundColor(totalReturnRate >= 0 ? .red : .green)
                                .fontWeight(.medium)
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

    private var totalMarketValue: Double { positions.reduce(0) { $0 + $1.marketValue } }
    private var totalCost: Double { positions.reduce(0) { $0 + Double($1.shares) * $1.costPrice } }
    private var totalProfit: Double { totalMarketValue - totalCost }
    private var totalReturnRate: Double {
        guard totalCost > 0 else { return 0 }
        return totalProfit / totalCost * 100
    }

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

struct PositionRow: View {
    let position: StockPosition

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(position.name)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.2f", position.marketValue))
                    .fontWeight(.medium)
            }
            HStack {
                Text("\(position.shares)股")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "成本 %.2f", position.costPrice))
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
                Section("股票信息") {
                    TextField("股票名称 (如 紫金矿业)", text: $name)
                    TextField("代码 (如 sh601899)", text: $symbol)
                        .textInputAutocapitalization(.never)
                    TextField("持仓数量 (股)", text: $shares)
                        .keyboardType(.numberPad)
                    TextField("成本价格", text: $costPrice)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("添加持仓")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let s = Int(shares), let price = Double(costPrice), !name.isEmpty else { return }
                        onAdd(StockPosition(
                            symbol: symbol.isEmpty ? name : symbol,
                            name: name, shares: s, costPrice: price
                        ))
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.isEmpty || shares.isEmpty || costPrice.isEmpty)
                }
            }
        }
    }
}
