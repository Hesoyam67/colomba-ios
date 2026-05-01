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
                Text("usage.nav_title")
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
        .navigationTitle(String(localized: "usage.nav_title"))
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView(String(localized: "usage.loading"))
                .accessibilityLabel("Loading usage")
        case let .loaded(snapshot, source):
            UsagePanel(snapshot: snapshot, source: source, viewModel: viewModel)
        case let .failed(message):
            Text(message)
                .foregroundStyle(Color.colomba.error)
                .accessibilityLabel(message)
        }
    }

    /// Format: usage.updated_from_format contains one source label.
    private var updatedFromText: String {
        let sourceText = source == .cache
            ? String(localized: "usage.source_cache")
            : String(localized: "usage.source_server")
        return String(format: NSLocalizedString("usage.updated_from_format", comment: ""), sourceText)
    }

    /// Format: usage.overage_format contains one formatted event count.
    private var overageText: String {
        String(format: NSLocalizedString("usage.overage_format", comment: ""), snapshot.overageEvents.formatted())
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
            Text(updatedFromText)
                .font(.colomba.caption)
                .foregroundStyle(Color.colomba.text.secondary)
            if snapshot.overageEvents > 0 {
                Text(overageText)
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.error)
                    .accessibilityLabel(overageText)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
