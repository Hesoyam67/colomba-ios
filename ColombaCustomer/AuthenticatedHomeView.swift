import ColombaAuth
import ColombaDesign
import SwiftUI

struct AuthenticatedHomeView: View {
    let authController: AuthController
    let session: AuthSession

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                    Text("Signed in")
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.success)
                        .accessibilityLabel("Signed in")
                    Text("Welcome, \(session.customer.displayName)")
                        .font(.colomba.titleLg)
                        .foregroundStyle(Color.colomba.text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Welcome, \(session.customer.displayName)")
                    Text("Your secure session is active. Review plan and billing readiness from the dashboard.")
                        .font(.colomba.bodyLg)
                        .foregroundStyle(Color.colomba.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Customer session active")
                    NavigationLink("View plans") {
                        PlansListView()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("View available Colomba plans")
                    NavigationLink("View usage") {
                        UsageView()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("View usage this month")
                    StripePortalButton()
                }
                HStack(spacing: ColombaSpacing.space3) {
                    Button("Refresh session") {
                        Task {
                            await authController.refreshSession()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Refresh secure session")
                    Button("Sign out") {
                        authController.signOut()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Sign out of Colomba")
                }
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
}
