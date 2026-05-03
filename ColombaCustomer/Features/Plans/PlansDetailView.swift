import ColombaDesign
import ColombaNetworking
import SwiftUI

struct PlansDetailView: View {
    let plan: Plan
    let currency: String

    @Environment(\.dismiss)
    private var dismiss
    @State private var isShowingSelectionConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                    Text(plan.name)
                        .font(.colomba.display)
                        .foregroundStyle(Color.colomba.text.primary)
                    Text(priceText)
                        .font(.colomba.billingFigure)
                        .foregroundStyle(Color.colomba.primary)
                        .accessibilityLabel(priceAccessibilityText)
                }
                VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                    Text("plans.included")
                        .font(.colomba.titleMd)
                    Text(eventsText)
                        .font(.colomba.bodyLg)
                        .accessibilityLabel(eventsAccessibilityText)
                    ForEach(plan.features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .font(.colomba.bodyMd)
                            .foregroundStyle(Color.colomba.text.secondary)
                            .accessibilityLabel(feature)
                    }
                }
                UsageSummaryRow(snapshot: .fixtureCurrentMonth)
                Button(chooseText) {
                    isShowingSelectionConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(chooseAccessibilityText)
                .accessibilityHint(String(localized: "plans.upgrade_hint"))
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 620, alignment: .leading)
        }
        .background(Color.colomba.bg.base)
        .navigationTitle(plan.name)
        .alert(selectionTitle, isPresented: $isShowingSelectionConfirmation) {
            Button(String(localized: "plans.selection_done")) {
                dismiss()
            }
        } message: {
            Text(selectionMessage)
        }
    }

    /// Format: plans.price_format contains currency and formatted amount.
    private var priceText: String {
        let amount = String(describing: Decimal(plan.monthlyPriceMinor) / Decimal(100))
        return String(format: NSLocalizedString("plans.price_format", comment: ""), currency, amount)
    }

    /// Format: plans.price_accessibility_format contains currency and monthly amount.
    private var priceAccessibilityText: String {
        String(
            format: NSLocalizedString("plans.price_accessibility_format", comment: ""),
            currency,
            plan.monthlyPriceMinor / 100
        )
    }

    /// Format: plans.events_format contains one formatted event count.
    private var eventsText: String {
        String(format: NSLocalizedString("plans.events_format", comment: ""), plan.includedEvents.formatted())
    }

    /// Format: plans.events_accessibility_format contains one formatted event count.
    private var eventsAccessibilityText: String {
        String(
            format: NSLocalizedString("plans.events_accessibility_format", comment: ""),
            plan.includedEvents.formatted()
        )
    }

    /// Format: plans.choose_format contains one plan name.
    private var chooseText: String {
        String(format: NSLocalizedString("plans.choose_format", comment: ""), plan.name)
    }

    /// Format: plans.choose_accessibility_format contains one plan name.
    private var chooseAccessibilityText: String {
        String(format: NSLocalizedString("plans.choose_accessibility_format", comment: ""), plan.name)
    }

    /// Format: plans.selection_title_format contains one plan name.
    private var selectionTitle: String {
        String(format: NSLocalizedString("plans.selection_title_format", comment: ""), plan.name)
    }

    /// Format: plans.selection_message_format contains one plan name.
    private var selectionMessage: String {
        String(format: NSLocalizedString("plans.selection_message_format", comment: ""), plan.name)
    }
}

#Preview {
    PlansDetailView(
        plan: Plan(
            id: "plan_starter_chf_monthly",
            name: "Piccola",
            tier: .starter,
            monthlyPriceMinor: 4_900,
            includedEvents: 1_000,
            features: ["Reservation capture", "Basic analytics"]
        ),
        currency: "CHF"
    )
}
