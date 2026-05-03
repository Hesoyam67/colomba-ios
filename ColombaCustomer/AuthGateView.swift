import ColombaAuth
import ColombaDesign
import SwiftUI

struct AuthGateView: View {
    let authController: AuthController

    var body: some View {
        Group {
            switch authController.state {
            case .restoring:
                restoringView
            case .signedOut,
                 .requestingMagicLink,
                 .magicLinkSent,
                 .verifyingMagicLink,
                 .authenticatingWithApple,
                 .authenticatingWithGoogle,
                 .failed:
                SignedOutAuthView(authController: authController, state: authController.state)
            case let .authenticated(session):
                AuthenticatedHomeView(authController: authController, session: session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
    }

    private var restoringView: some View {
        VStack(spacing: ColombaSpacing.space4) {
            ProgressView()
                .controlSize(.large)
                .accessibilityLabel("Restoring Colomba session")
            Text("auth.colomba_brand")
                .font(.colomba.display)
                .foregroundStyle(Color.colomba.primary)
                .accessibilityLabel("Colomba")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Colomba session restore screen")
    }
}
