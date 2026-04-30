import SafariServices
import SwiftUI

struct StripePortalSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        controller.preferredControlTintColor = .systemBlue
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

@MainActor
final class StripePortalCoordinator: ObservableObject {
    @Published var portalItem: StripePortalItem?
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    private let service: PortalSessionService

    init(service: PortalSessionService = PortalSessionService()) {
        self.service = service
    }

    func openPortal() async {
        isLoading = true
        defer { isLoading = false }
        do {
            portalItem = StripePortalItem(url: try await service.createPortalURL())
            errorMessage = nil
        } catch let error as PortalSessionService.PortalSessionError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Billing portal is unavailable. Please try again."
        }
    }

    func closePortal() {
        portalItem = nil
    }
}

struct StripePortalButton: View {
    @StateObject private var coordinator: StripePortalCoordinator

    init() {
        _coordinator = StateObject(wrappedValue: StripePortalCoordinator())
    }

    init(coordinator: StripePortalCoordinator) {
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task { await coordinator.openPortal() }
            } label: {
                if coordinator.isLoading {
                    ProgressView()
                } else {
                    Text("Manage subscription")
                }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Manage subscription")
            .accessibilityHint("Opens the Stripe customer portal in Safari")
            if let errorMessage = coordinator.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel(errorMessage)
            }
        }
        .sheet(item: $coordinator.portalItem) { item in
            StripePortalSheet(url: item.url)
                .ignoresSafeArea()
        }
    }
}

struct StripePortalItem: Identifiable, Equatable {
    let url: URL

    var id: String { url.absoluteString }
}
