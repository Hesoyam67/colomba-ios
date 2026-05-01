import ColombaAuth
import ColombaDesign
import SwiftUI

struct SettingsView: View {
    let authController: AuthController
    let welcomeName: String

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "settings.account")) {
                    Text(welcomeName)
                        .font(.colomba.bodyLg)
                        .foregroundStyle(Color.colomba.text.primary)
                        .accessibilityLabel(welcomeName)

                    Button(String(localized: "settings.sign_out"), role: .destructive) {
                        authController.signOut()
                    }
                    .accessibilityLabel(Text("settings.sign_out"))
                }

                Section(String(localized: "settings.app")) {
                    NavigationLink {
                        UsageView()
                    } label: {
                        Text("settings.usage")
                    }
                    .accessibilityLabel(Text("settings.usage"))

                    Text("settings.language")
                        .foregroundStyle(Color.colomba.text.secondary)
                        .accessibilityLabel(Text("settings.language"))
                    Text("settings.about")
                        .foregroundStyle(Color.colomba.text.secondary)
                        .accessibilityLabel(Text("settings.about"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.colomba.bg.base)
            .navigationTitle(String(localized: "tabs.settings"))
        }
    }
}

#Preview {
    SettingsView(authController: .productionMock(), welcomeName: "Papu")
}
