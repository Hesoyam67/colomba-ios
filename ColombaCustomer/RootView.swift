import ColombaAuth
import ColombaCore
import SwiftUI

struct RootView: View {
    @State private var authController = AuthController.productionMock()

    var body: some View {
        Group {
            switch authController.state {
            case .restoring,
                 .signedOut,
                 .requestingMagicLink,
                 .magicLinkSent,
                 .verifyingMagicLink,
                 .authenticatingWithApple,
                 .failed:
                AuthGateView(authController: authController)
            case let .authenticated(session):
                RootTabShell(authController: authController, session: session)
            }
        }
        .background(Color.colomba.bg.base)
        .onAppear {
            ColdStart.markRootViewAppeared()
        }
        .task {
            await authController.restoreSession()
        }
        .onOpenURL { url in
            Task {
                await authController.handleMagicLinkURL(url)
            }
        }
    }
}

private struct RootTabShell: View {
    let authController: AuthController
    let session: AuthSession

    var body: some View {
        TabView {
            AuthenticatedHomeView(authController: authController, session: session)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("tabs.home"))
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(LocalizedStringKey("tabs.home"))
                }

            NavigationStack {
                MyReservationsView(
                    viewModel: MyReservationsViewModel(service: ReservationService())
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.reservations"))
            .tabItem {
                Image(systemName: "calendar")
                Text(LocalizedStringKey("tabs.reservations"))
            }

            NavigationStack {
                PlansListView()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.plans"))
            .tabItem {
                Image(systemName: "creditcard")
                Text(LocalizedStringKey("tabs.plans"))
            }

            NavigationStack {
                HeidiChatView()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.heidi"))
            .tabItem {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text(LocalizedStringKey("tabs.heidi"))
            }

            SettingsView(authController: authController, customer: session.customer)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("tabs.settings"))
                .tabItem {
                    Image(systemName: "gear")
                    Text(LocalizedStringKey("tabs.settings"))
                }
        }
    }
}

#Preview {
    RootView()
}
