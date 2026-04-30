import ColombaDesign
import ColombaNetworking
import SwiftUI

struct UsageSummaryRow: View {
    let snapshot: UsageSnapshot

    private var usageText: String {
        "\(snapshot.usedEvents.formatted()) / \(snapshot.includedEvents.formatted()) events"
    }

    private var accessibilityText: String {
        "\(snapshot.usedEvents.formatted()) of \(snapshot.includedEvents.formatted()) events used this month"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                Text("Usage this month")
                    .font(.colomba.titleMd)
                    .foregroundStyle(Color.colomba.text.primary)
                Text(usageText)
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
            }
            Spacer()
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(Color.colomba.primary)
        }
        .padding(ColombaSpacing.space4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}
