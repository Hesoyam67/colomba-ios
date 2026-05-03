import ColombaDesign
import ColombaNetworking
import SwiftUI

struct PlansDetailView: View {
    let plan: Plan
    let currency: String
    @Binding var selectedPlanId: String
    @State private var showPaywall = false

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
                    Text(minutesText)
                        .font(.colomba.bodyLg)
                        .accessibilityLabel(minutesAccessibilityText)
                    ForEach(plan.features, id: \.self) { feature in
                        Label(LocalizedStringKey(feature), systemImage: "checkmark.circle.fill")
                            .font(.colomba.bodyMd)
                            .foregroundStyle(Color.colomba.text.secondary)
                            .accessibilityLabel(Text(LocalizedStringKey(feature)))
                    }
                }
                UsageSummaryRow(snapshot: planUsageSnapshot)
                if isSelected {
                    Label(selectedText, systemImage: "checkmark.circle.fill")
                        .font(.colomba.bodyMd)
                        .foregroundStyle(Color.colomba.primary)
                        .accessibilityLabel(selectedText)
                }
                Button(chooseText) {
                    selectedPlanId = plan.id
                    showPaywall = true
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
        .navigationDestination(isPresented: $showPaywall) {
            PaywallView()
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

    /// Format: plans.minutes_format contains one formatted minute count.
    private var minutesText: String {
        String(format: NSLocalizedString("plans.minutes_format", comment: ""), plan.includedMinutes.formatted())
    }

    /// Format: plans.minutes_accessibility_format contains one formatted minute count.
    private var minutesAccessibilityText: String {
        String(
            format: NSLocalizedString("plans.minutes_accessibility_format", comment: ""),
            plan.includedMinutes.formatted()
        )
    }

    private var planUsageSnapshot: UsageSnapshot {
        UsageSnapshot(
            period: UsagePeriod.currentMonth.rawValue,
            usedMinutes: UsageSnapshot.fixtureCurrentMonth.usedMinutes,
            includedMinutes: plan.includedMinutes,
            overageMinutes: max(UsageSnapshot.fixtureCurrentMonth.usedMinutes - plan.includedMinutes, 0),
            planId: plan.id,
            updatedAt: UsageSnapshot.fixtureCurrentMonth.updatedAt
        )
    }

    private var isSelected: Bool {
        selectedPlanId == plan.id
    }

    /// Format: plans.choose_format contains one plan name.
    private var chooseText: String {
        String(format: NSLocalizedString("plans.choose_format", comment: ""), plan.name)
    }

    /// Format: plans.choose_accessibility_format contains one plan name.
    private var chooseAccessibilityText: String {
        String(format: NSLocalizedString("plans.choose_accessibility_format", comment: ""), plan.name)
    }

    /// Format: plans.selected_format contains one plan name.
    private var selectedText: String {
        String(format: NSLocalizedString("plans.selected_format", comment: ""), plan.name)
    }
}

#Preview {
    PlansDetailView(
        plan: Plan(
            id: "plan_starter_chf_monthly",
            name: "Piccola",
            tier: .starter,
            monthlyPriceMinor: 4_900,
            includedMinutes: 1_000,
            features: ["plans.feature.reservation_capture", "plans.feature.basic_analytics"]
        ),
        currency: "CHF",
        selectedPlanId: .constant("")
    )
}
