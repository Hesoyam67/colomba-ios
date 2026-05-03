import ColombaAuth
import ColombaDesign
import SwiftUI

struct AuthenticatedHomeView: View {
    let authController: AuthController
    let session: AuthSession
    let reservationService: ReservationServiceProtocol

    init(
        authController: AuthController,
        session: AuthSession,
        reservationService: ReservationServiceProtocol = ReservationService()
    ) {
        self.authController = authController
        self.session = session
        self.reservationService = reservationService
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                    Text("auth.signed_in")
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.success)
                        .accessibilityLabel("Signed in")
                    Text(welcomeName)
                        .font(.colomba.titleLg)
                        .foregroundStyle(Color.colomba.text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Welcome, \(session.customer.displayName)")
                    Text("auth.session_copy")
                        .font(.colomba.bodyLg)
                        .foregroundStyle(Color.colomba.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Customer session active")
                    NavigationLink(String(localized: "auth.view_plans")) {
                        PlansListView()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("View available Colomba plans")
                    NavigationLink(String(localized: "auth.view_usage")) {
                        UsageView()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("View usage this month")
                    NavigationLink(String(localized: "auth.reserve_table")) {
                        RestaurantListView(
                            viewModel: ReservationViewModel(
                                service: reservationService,
                                prefilledName: session.customer.displayName
                            )
                        )
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Reserve a table at a restaurant")
                    StripePortalButton()
                }
                Button(String(localized: "auth.refresh_session")) {
                    Task {
                        await authController.refreshSession()
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Refresh secure session")
                Spacer(minLength: ColombaSpacing.space4)
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 620, maxHeight: .infinity, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.colomba.bg.base)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Authenticated Colomba home screen")
        }
    }

    /// Format: auth.welcome_name_format contains one %@ display name.
    private var welcomeName: String {
        String(format: NSLocalizedString("auth.welcome_name_format", comment: ""), session.customer.displayName)
    }
}
