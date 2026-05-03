import ColombaBilling
import ColombaDesign
import SwiftUI

@MainActor
struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel
    @StateObject private var workspaceStore = WorkspaceStore()
    @State private var showWorkspaceSetup = false
    @State private var savedWorkspaceName: String?

    init() {
        _viewModel = StateObject(wrappedValue: PaywallViewModel())
    }

    init(viewModel: PaywallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space5) {
            Text("paywall.upgrade_title")
                .font(.colomba.display)
                .accessibilityLabel("Upgrade Colomba")
            content
            Button(String(localized: "paywall.restore_purchases")) {
                Task { await viewModel.restore() }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Restore purchases")
        }
        .padding(ColombaSpacing.Screen.margin)
        .background(Color.colomba.bg.base)
        .navigationDestination(isPresented: $showWorkspaceSetup) {
            WorkspaceSetupView(workspace: .draft()) { workspace in
                workspaceStore.upsert(workspace)
                savedWorkspaceName = workspace.name
            }
        }
        .task {
            guard case .idle = viewModel.state else {
                return
            }
            await viewModel.load()
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loadingProducts:
            ProgressView(String(localized: "paywall.loading_products"))
                .accessibilityLabel("Loading products")
        case let .ready(products):
            ForEach(products) { product in
                Button {
                    Task { await viewModel.purchase(product: product) }
                } label: {
                    VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                        Text(product.displayName).font(.colomba.titleMd)
                        Text(productPriceText(for: product)).font(.colomba.billingFigure)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(productBuyAccessibility(for: product))
                .accessibilityHint(String(localized: "paywall.purchase_hint"))
            }
        case let .purchasing(productID):
            ProgressView(purchasingText(for: productID))
                .accessibilityLabel("Purchase in progress")
        case let .purchased(productID):
            VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                Text(purchasedText(for: productID))
                    .foregroundStyle(Color.colomba.success)
                    .accessibilityLabel("Purchase complete")

                Text("Next: create the workspace that this plan will power.")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)

                Button("Set up workspace") {
                    showWorkspaceSetup = true
                }
                .buttonStyle(.borderedProminent)

                if let savedWorkspaceName {
                    Label("Saved \(savedWorkspaceName)", systemImage: "checkmark.circle.fill")
                        .font(.colomba.bodyMd)
                        .foregroundStyle(Color.colomba.success)
                }
            }
        case .cancelled:
            Text(PaywallError.purchaseCancelled.userMessage)
                .accessibilityLabel("Purchase cancelled")
        case .pending:
            Text(PaywallError.purchasePending.userMessage)
                .accessibilityLabel("Purchase pending")
        case let .failed(error):
            Text(error.userMessage)
                .foregroundStyle(Color.colomba.error)
                .accessibilityLabel(error.userMessage)
        }
    }

    /// Format: paywall.price_format contains display price and billing interval.
    private func productPriceText(for product: ColombaProduct) -> String {
        String(
            format: NSLocalizedString("paywall.price_format", comment: ""),
            product.displayPrice,
            product.interval
        )
    }

    /// Format: paywall.buy_accessibility_format contains product name, price, and interval.
    private func productBuyAccessibility(for product: ColombaProduct) -> String {
        String(
            format: NSLocalizedString("paywall.buy_accessibility_format", comment: ""),
            product.displayName,
            product.displayPrice,
            product.interval
        )
    }

    /// Format: paywall.purchasing_format contains one product identifier.
    private func purchasingText(for productID: String) -> String {
        String(format: NSLocalizedString("paywall.purchasing_format", comment: ""), productID)
    }

    /// Format: paywall.purchased_format contains one product identifier.
    private func purchasedText(for productID: String) -> String {
        String(format: NSLocalizedString("paywall.purchased_format", comment: ""), productID)
    }
}
