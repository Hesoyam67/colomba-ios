import ColombaDesign
import ColombaNetworking
import SwiftUI

struct PlansDetailView: View {
    let plan: Plan
    let currency: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                    Text(plan.name)
                        .font(.colomba.display)
                        .foregroundStyle(Color.colomba.text.primary)
                    Text("\(currency) \(Decimal(plan.monthlyPriceMinor) / Decimal(100))/month")
                        .font(.colomba.billingFigure)
                        .foregroundStyle(Color.colomba.primary)
                        .accessibilityLabel("\(currency) \(plan.monthlyPriceMinor / 100) per month")
                }
                VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                    Text("Included")
                        .font(.colomba.titleMd)
                    Text("\(plan.includedEvents.formatted()) events per month")
                        .font(.colomba.bodyLg)
                        .accessibilityLabel("\(plan.includedEvents.formatted()) events included per month")
                    ForEach(plan.features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .font(.colomba.bodyMd)
                            .foregroundStyle(Color.colomba.text.secondary)
                            .accessibilityLabel(feature)
                    }
                }
                UsageSummaryRow(snapshot: .fixtureCurrentMonth)
                Button("Choose \(plan.name)") {}
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Choose \(plan.name) plan")
                    .accessibilityHint("Opens the secure upgrade flow")
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 620, alignment: .leading)
        }
        .background(Color.colomba.bg.base)
        .navigationTitle(plan.name)
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
