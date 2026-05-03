import ColombaDesign
import ColombaNetworking
import SwiftUI

@MainActor
struct PlansListView: View {
    @StateObject private var viewModel: PlansViewModel
    @AppStorage(
        "colomba.plans.selectedPlanId"
    )
    private var selectedPlanId = ""

    init() {
        _viewModel = StateObject(wrappedValue: PlansViewModel())
    }

    init(viewModel: PlansViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView(String(localized: "plans.loading"))
                        .accessibilityLabel("Loading plans")
                case let .failed(error):
                    ContentUnavailableView(
                        String(localized: "plans.unavailable"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.userMessageKey)
                    )
                    .accessibilityLabel("Plans unavailable")
                case let .loaded(catalog):
                    ScrollView {
                        LazyVStack(spacing: ColombaSpacing.space4) {
                            ForEach(catalog.plans, id: \.id) { plan in
                                NavigationLink {
                                    PlansDetailView(
                                        plan: plan,
                                        currency: catalog.currency,
                                        selectedPlanId: $selectedPlanId
                                    )
                                } label: {
                                    PlanCardView(
                                        plan: plan,
                                        currency: catalog.currency,
                                        viewModel: viewModel,
                                        isSelected: selectedPlanId == plan.id
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(openDetailsText(for: plan))
                            }
                        }
                        .padding(ColombaSpacing.Screen.margin)
                    }
                    .background(Color.colomba.bg.base)
                }
            }
            .navigationTitle(String(localized: "plans.nav_title"))
        }
        .task {
            guard case .idle = viewModel.state else {
                return
            }
            await viewModel.load()
        }
    }

    /// Format: plans.open_details_format contains one plan name.
    private func openDetailsText(for plan: Plan) -> String {
        String(format: NSLocalizedString("plans.open_details_format", comment: ""), plan.name)
    }
}

private struct PlanCardView: View {
    let plan: Plan
    let currency: String
    let viewModel: PlansViewModel
    let isSelected: Bool

    private var accessibilitySummary: String {
        [
            plan.name,
            viewModel.priceText(for: plan, currency: currency),
            viewModel.includedMinutesText(for: plan),
            featuresSummary
        ].joined(separator: ", ")
    }

    private var featuresSummary: String {
        plan.features.map { NSLocalizedString($0, comment: "") }.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.name)
                    .font(.colomba.titleMd)
                    .foregroundStyle(Color.colomba.text.primary)
                Spacer()
                if isSelected {
                    Text("plans.selected_badge")
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.primary)
                        .padding(.horizontal, ColombaSpacing.space2)
                        .padding(.vertical, ColombaSpacing.space1)
                        .background(Color.colomba.primary.opacity(0.12))
                        .clipShape(Capsule())
                }
                Text(viewModel.priceText(for: plan, currency: currency))
                    .font(.colomba.billingFigure)
                    .foregroundStyle(Color.colomba.primary)
            }
            Text(viewModel.includedMinutesText(for: plan))
                .font(.colomba.bodyMd)
                .foregroundStyle(Color.colomba.text.secondary)
            Text(featuresSummary)
                .font(.colomba.caption)
                .foregroundStyle(Color.colomba.text.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(ColombaSpacing.Card.padding)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
                .stroke(
                    isSelected ? Color.colomba.primary : Color.colomba.border.hairline,
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }
}

#Preview {
    PlansListView()
}
