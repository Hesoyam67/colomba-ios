import ColombaAuth
import ColombaDesign
import SwiftUI

struct AuthRootHost: View {
    @State private var authController = AuthController.productionMock()

    var body: some View {
        AuthGateView(authController: authController)
            .background(Color.colomba.bg.base)
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
