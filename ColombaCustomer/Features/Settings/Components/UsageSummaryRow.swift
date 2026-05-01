import ColombaDesign
import ColombaNetworking
import SwiftUI

struct UsageSummaryRow: View {
    let snapshot: UsageSnapshot

    private var usageText: String {
        String(
            format: NSLocalizedString("usage.summary_format", comment: ""),
            snapshot.usedEvents.formatted(),
            snapshot.includedEvents.formatted()
        )
    }

    private var accessibilityText: String {
        String(
            format: NSLocalizedString("usage.accessibility_format", comment: ""),
            snapshot.usedEvents.formatted(),
            snapshot.includedEvents.formatted()
        )
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                Text("usage.this_month")
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
