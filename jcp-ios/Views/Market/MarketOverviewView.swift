import SwiftUI

struct MarketOverviewView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @State private var selectedSegment = 0

    let segments = ["News", "Trends", "LHB", "Moves", "Flow", "Reports"]
    let icons = ["newspaper", "flame", "trophy", "bolt", "chart.bar", "doc.text"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.jcpBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    MarketIndicesView(indices: marketVM.marketIndices)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<segments.count, id: \.self) { i in
                                Button(action: { selectedSegment = i }) {
                                    Label(segments[i], systemImage: icons[i])
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedSegment == i ? Color.jcpAccent : Color.jcpSurface)
                                        .foregroundColor(selectedSegment == i ? .white : .jcpTextSecondary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }

                    // Content
                    TabView(selection: $selectedSegment) {
                        TelegraphNewsView()
                            .tag(0)
                        HotTrendsView()
                            .tag(1)
                        LongHuBangView()
                            .tag(2)
                        MarketMovesView()
                            .tag(3)
                        BoardFundFlowView()
                            .tag(4)
                        ResearchReportsView()
                            .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Market")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { marketVM.loadAllData() }
        }
    }
}

// MARK: - Hot Trends
struct HotTrendsView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @State private var selectedPlatform: String = "weibo"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Constants.hotTrendPlatforms, id: \.id) { p in
                        Button(action: { selectedPlatform = p.id }) {
                            HStack(spacing: 4) {
                                Image(systemName: p.icon).font(.caption)
                                Text(p.name).font(.caption)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(selectedPlatform == p.id ? Color.jcpAccent : Color.jcpSurface)
                            .foregroundColor(selectedPlatform == p.id ? .white : .jcpTextSecondary)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 8)
            }

            if let trend = marketVM.hotTrends.first(where: { $0.platform == selectedPlatform }), !trend.items.isEmpty {
                List(trend.items) { item in
                    HStack(spacing: 12) {
                        Text("\(item.rank)").font(.headline).frame(width: 30)
                            .foregroundColor(item.rank <= 3 ? .jcpRed : .jcpTextSecondary)
                        Text(item.title).font(.subheadline).foregroundColor(.jcpTextPrimary).lineLimit(2)
                        Spacer()
                        if item.rank <= 3 { Image(systemName: "flame.fill").foregroundColor(.orange).font(.caption) }
                    }
                    .padding(.vertical, 4).listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
                .refreshable { marketVM.loadHotTrends() }
            } else {
                ProgressView().padding().frame(maxHeight: .infinity)
            }
        }
        .background(Color.jcpBackground)
    }
}

// MARK: - LongHuBang
struct LongHuBangView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    var body: some View {
        VStack(spacing: 0) {
            if marketVM.longHuBangItems.isEmpty {
                Button("Load LongHuBang") { marketVM.loadLongHuBang() }
                    .padding().background(Color.jcpAccent).foregroundColor(.white).cornerRadius(8)
                    .padding(.top, 40)
            } else {
                List(marketVM.longHuBangItems) { item in
                    HStack {
                        VStack(alignment: .leading) { Text(item.name).font(.subheadline).foregroundColor(.jcpTextPrimary); Text(item.symbol).font(.system(size:10)).foregroundColor(.jcpTextTertiary) }
                        Text(item.typeName).font(.system(size:10)).foregroundColor(.jcpAccent)
                        Text(item.netAmount.formatAmount()).font(.subheadline).fontWeight(.medium).foregroundColor(item.netAmount >= 0 ? .jcpRed : .jcpGreen)
                    }
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
                .refreshable { marketVM.loadLongHuBang() }
            }
        }
        .background(Color.jcpBackground)
    }
}

// MARK: - Market Moves
struct MarketMovesView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    var body: some View {
        VStack(spacing: 0) {
            if marketVM.marketMoves.isEmpty {
                Button("Load Market Moves") { marketVM.loadMarketMoves() }
                    .padding().background(Color.jcpAccent).foregroundColor(.white).cornerRadius(8).padding(.top, 40)
            } else {
                List(marketVM.marketMoves) { move in
                    HStack {
                        VStack(alignment: .leading) { Text(move.name).font(.subheadline).foregroundColor(.jcpTextPrimary); Text(move.symbol).font(.system(size:10)).foregroundColor(.jcpTextTertiary) }
                        Spacer()
                        Text(move.moveTypeName).font(.system(size:10)).padding(.horizontal,6).padding(.vertical,2).background(Color.jcpAccent.opacity(0.2)).foregroundColor(.jcpAccent).cornerRadius(4)
                    }
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
                .refreshable { marketVM.loadMarketMoves() }
            }
        }
        .background(Color.jcpBackground)
    }
}

// MARK: - Board Fund Flow
struct BoardFundFlowView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    var body: some View {
        VStack(spacing: 0) {
            if marketVM.boardFundFlows.isEmpty {
                Button("Load Fund Flow") { marketVM.loadBoardFundFlow() }
                    .padding().background(Color.jcpAccent).foregroundColor(.white).cornerRadius(8).padding(.top, 40)
            } else {
                List(marketVM.boardFundFlows) { flow in
                    HStack {
                        Text("\(flow.rank)").font(.subheadline).frame(width:40).foregroundColor(flow.rank <= 3 ? .jcpRed : .jcpTextSecondary)
                        Text(flow.boardName).font(.subheadline).foregroundColor(.jcpTextPrimary).frame(maxWidth:.infinity, alignment:.leading)
                        Text(flow.fundFlow.formatAmount()).font(.subheadline).fontWeight(.medium).foregroundColor(flow.fundFlow >= 0 ? .jcpRed : .jcpGreen)
                    }
                    .listRowBackground(Color.jcpBackground)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
                .refreshable { marketVM.loadBoardFundFlow() }
            }
        }
        .background(Color.jcpBackground)
    }
}
