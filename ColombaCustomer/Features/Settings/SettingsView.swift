import ColombaAuth
import ColombaDesign
import SwiftUI

struct SettingsView: View {
    let authController: AuthController
    let customer: Customer

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "settings.account")) {
                    VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                        Text(customer.displayName)
                            .font(.colomba.bodyLg)
                            .foregroundStyle(Color.colomba.text.primary)
                        Text(customer.email ?? String(localized: "settings.no_email"))
                            .font(.colomba.caption)
                            .foregroundStyle(Color.colomba.text.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        Text(
                            String(
                                format: NSLocalizedString(
                                    "profile.summary_format",
                                    tableName: "Profile",
                                    comment: ""
                                ),
                                customer.displayName,
                                customer.email ?? ""
                            )
                        )
                    )

                    NavigationLink {
                        ProfileEditView(authController: authController, customer: customer)
                    } label: {
                        Label(String(localized: "profile.edit", table: "Profile"), systemImage: "person.crop.circle")
                    }
                    .accessibilityLabel(Text(String(localized: "profile.edit", table: "Profile")))
                }

                Section(String(localized: "settings.primary_actions")) {
                    NavigationLink {
                        PlansListView()
                    } label: {
                        Label(String(localized: "settings.manage_plan"), systemImage: "creditcard")
                    }
                    .accessibilityLabel(Text("settings.manage_plan"))

                    NavigationLink {
                        MyReservationsView(viewModel: MyReservationsViewModel(service: ReservationService()))
                    } label: {
                        Label(String(localized: "settings.reservations"), systemImage: "calendar")
                    }
                    .accessibilityLabel(Text("settings.reservations"))
                }

                Section(String(localized: "settings.billing_usage")) {
                    NavigationLink {
                        UsageView()
                    } label: {
                        Label(String(localized: "settings.usage_minutes"), systemImage: "timer")
                    }
                    .accessibilityLabel(Text("settings.usage_minutes"))

                    Text("settings.usage_explanation")
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(Text("settings.usage_explanation"))
                }

                Section(String(localized: "settings.app")) {
                    LabeledContent(String(localized: "settings.language")) {
                        Text(customer.locale.rawValue)
                            .foregroundStyle(Color.colomba.text.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    LabeledContent(String(localized: "settings.about")) {
                        Text(String(localized: "settings.version_value"))
                            .foregroundStyle(Color.colomba.text.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }

                Section {
                    Button(String(localized: "settings.sign_out"), role: .destructive) {
                        authController.signOut()
                    }
                    .accessibilityLabel(Text("settings.sign_out"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.colomba.bg.base)
            .navigationTitle(String(localized: "tabs.settings"))
        }
    }
}

private struct ProfileEditView: View {
    let authController: AuthController
    let customer: Customer

    @Environment(
        \.dismiss
    )
    private var dismiss
    @State private var displayName: String
    @State private var errorMessage: String?

    init(authController: AuthController, customer: Customer) {
        self.authController = authController
        self.customer = customer
        _displayName = State(initialValue: customer.displayName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "profile.title", table: "Profile")) {
                    TextField(String(localized: "profile.display_name", table: "Profile"), text: $displayName)
                        .textContentType(.name)
                        .submitLabel(.next)
                        .accessibilityLabel(Text(String(localized: "profile.display_name", table: "Profile")))
                        .onChange(of: displayName) { _, newValue in
                            if newValue.count > 60 {
                                displayName = String(newValue.prefix(60))
                            }
                        }
                    Text(characterCountText)
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.text.secondary)
                        .accessibilityLabel(Text(characterCountText))

                    Text(String(localized: "profile.read_only_contact", table: "Profile"))
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.text.secondary)

                    LabeledContent(String(localized: "profile.email", table: "Profile")) {
                        Text(customer.email ?? String(localized: "profile.not_provided", table: "Profile"))
                            .foregroundStyle(Color.colomba.text.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    LabeledContent(String(localized: "profile.phone_number", table: "Profile")) {
                        Text(customer.phoneNumber ?? String(localized: "profile.not_provided", table: "Profile"))
                            .foregroundStyle(Color.colomba.text.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.colomba.caption)
                            .foregroundStyle(Color.colomba.error)
                            .accessibilityLabel(Text(errorMessage))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.colomba.bg.base)
            .navigationTitle(String(localized: "profile.edit", table: "Profile"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "profile.cancel", table: "Profile")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "profile.save", table: "Profile")) {
                        errorMessage = nil
                        Task {
                            do {
                                _ = try await authController.updateDisplayName(displayName)
                                dismiss()
                            } catch AuthFailure.invalidDisplayName {
                                errorMessage = String(
                                    localized: "profile.error_validation_format",
                                    table: "Profile"
                                )
                            } catch {
                                errorMessage = String(localized: "profile.error_generic", table: "Profile")
                            }
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.count <= 60 && name != customer.displayName
    }

    private var characterCountText: String {
        String(
            format: NSLocalizedString(
                "profile.character_count_format",
                tableName: "Profile",
                comment: ""
            ),
            displayName.count
        )
    }
}

#Preview {
    SettingsView(
        authController: .productionMock(),
        customer: Customer(
            id: "preview",
            displayName: "Papu",
            email: "owner@example.ch",
            phoneNumber: "+41791234567",
            locale: .englishSwitzerland
        )
    )
}
