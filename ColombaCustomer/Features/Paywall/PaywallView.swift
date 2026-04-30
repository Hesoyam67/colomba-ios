import ColombaBilling
import ColombaDesign
import SwiftUI

@MainActor
struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel

    init() {
        _viewModel = StateObject(wrappedValue: PaywallViewModel())
    }

    init(viewModel: PaywallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space5) {
            Text("Upgrade Colomba")
                .font(.colomba.display)
                .accessibilityLabel("Upgrade Colomba")
            content
            Button("Restore purchases") {
                Task { await viewModel.restore() }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Restore purchases")
        }
        .padding(ColombaSpacing.Screen.margin)
        .background(Color.colomba.bg.base)
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
            ProgressView("Loading products")
                .accessibilityLabel("Loading products")
        case let .ready(products):
            ForEach(products) { product in
                Button {
                    Task { await viewModel.purchase(product: product) }
                } label: {
                    VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                        Text(product.displayName).font(.colomba.titleMd)
                        Text("\(product.displayPrice) per \(product.interval)").font(.colomba.billingFigure)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Buy \(product.displayName), \(product.displayPrice) per \(product.interval)")
                .accessibilityHint("Starts the App Store purchase flow")
            }
        case let .purchasing(productID):
            ProgressView("Purchasing \(productID)")
                .accessibilityLabel("Purchase in progress")
        case let .purchased(productID):
            Text("Purchased \(productID)")
                .foregroundStyle(Color.colomba.success)
                .accessibilityLabel("Purchase complete")
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
}
