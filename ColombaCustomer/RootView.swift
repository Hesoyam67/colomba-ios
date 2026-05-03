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
                 .authenticatingWithGoogle,
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

private enum RootTab: Hashable {
    case home
    case reservations
    case plans
    case heidi
    case settings
}

private struct RootTabShell: View {
    let authController: AuthController
    let session: AuthSession
    @State private var selectedTab: RootTab = .home

    var body: some View {
        let reservationService = ReservationService(refreshToken: session.tokens.refreshToken)

        TabView(selection: $selectedTab) {
            AuthenticatedHomeView(
                authController: authController,
                session: session,
                reservationService: reservationService
            )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("tabs.home"))
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(LocalizedStringKey("tabs.home"))
                }
                .tag(RootTab.home)

            NavigationStack {
                MyReservationsView(
                    viewModel: MyReservationsViewModel(service: reservationService),
                    reservationService: reservationService,
                    prefilledName: session.customer.displayName
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.reservations"))
            .tabItem {
                Image(systemName: "calendar")
                Text(LocalizedStringKey("tabs.reservations"))
            }
            .tag(RootTab.reservations)

            NavigationStack {
                PlansListView()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.plans"))
            .tabItem {
                Image(systemName: "creditcard")
                Text(LocalizedStringKey("tabs.plans"))
            }
            .tag(RootTab.plans)

            NavigationStack {
                HeidiChatView(
                    viewModel: HeidiChatViewModel(
                        service: HeidiService(
                            mode: .live(
                                HeidiLiveConfiguration(
                                    sessionId: "ios-\(session.customer.id)",
                                    userId: session.customer.id,
                                    bearerToken: session.tokens.accessToken
                                )
                            )
                        )
                    ),
                    reservationService: reservationService,
                    prefilledName: session.customer.displayName,
                    onGoHome: { selectedTab = .home }
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("tabs.heidi"))
            .tabItem {
                Image(systemName: "sparkles")
                Text(LocalizedStringKey("tabs.heidi"))
            }
            .tag(RootTab.heidi)

            SettingsView(
                authController: authController,
                customer: session.customer,
                reservationService: reservationService,
                prefilledName: session.customer.displayName
            )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text("tabs.settings"))
                .tabItem {
                    Image(systemName: "gear")
                    Text(LocalizedStringKey("tabs.settings"))
                }
                .tag(RootTab.settings)
        }
    }
}

#Preview {
    RootView()
}
