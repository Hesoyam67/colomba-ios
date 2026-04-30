import ColombaDesign
import ColombaNetworking
import SwiftUI

@MainActor
struct UsageView: View {
    @StateObject private var viewModel: UsageViewModel

    init() {
        _viewModel = StateObject(wrappedValue: UsageViewModel())
    }

    init(viewModel: UsageViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space5) {
                Text("Usage")
                    .font(.colomba.display)
                    .foregroundStyle(Color.colomba.text.primary)
                content
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 620, alignment: .leading)
        }
        .background(Color.colomba.bg.base)
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
        .navigationTitle("Usage")
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading usage")
                .accessibilityLabel("Loading usage")
        case let .loaded(snapshot, source):
            UsagePanel(snapshot: snapshot, source: source, viewModel: viewModel)
        case let .failed(message):
            Text(message)
                .foregroundStyle(Color.colomba.error)
                .accessibilityLabel(message)
        }
    }
}

struct UsagePanel: View {
    let snapshot: UsageSnapshot
    let source: UsageViewModel.Source
    let viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
            Text(viewModel.usageText(for: snapshot))
                .font(.colomba.billingFigure)
                .foregroundStyle(Color.colomba.primary)
                .accessibilityLabel(viewModel.accessibilityText(for: snapshot))
            ProgressView(value: viewModel.progress(for: snapshot))
                .accessibilityLabel(viewModel.accessibilityText(for: snapshot))
            Text("Updated from \(source == .cache ? "cache" : "server")")
                .font(.colomba.caption)
                .foregroundStyle(Color.colomba.text.secondary)
            if snapshot.overageEvents > 0 {
                Text("\(snapshot.overageEvents.formatted()) overage events")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.error)
                    .accessibilityLabel("\(snapshot.overageEvents.formatted()) overage events")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
