import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "settings.account")) {
                    Button(String(localized: "settings.sign_out")) {}
                        .disabled(true)
                }

                Section(String(localized: "settings.app")) {
                    NavigationLink {
                        UsageView()
                    } label: {
                        Text("settings.usage")
                    }

                    Text("settings.language")
                        .disabled(true)
                    Text("settings.about")
                        .disabled(true)
                }
            }
            .navigationTitle(String(localized: "tabs.settings"))
        }
    }
}

#Preview {
    SettingsView()
}
