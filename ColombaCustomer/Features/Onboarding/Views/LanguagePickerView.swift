import ColombaDesign
import SwiftUI

public struct LanguagePickerView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        let copy = OnboardingCopy.copy(for: viewModel.selectedLanguage)
        let selectedLanguage = viewModel.selectedLanguage ?? .deCH

        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(copy.languageTitle)
                    .font(.custom("Fraunces", size: 34, relativeTo: .largeTitle).weight(.bold))
                    .foregroundStyle(Color.colomba.text.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.languagePicker.title")

                Text(copy.languageBody)
                    .font(.custom("Inter", size: 17, relativeTo: .body))
                    .foregroundStyle(Color.colomba.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.languagePicker.body")
            }

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        viewModel.selectLanguage(language)
                        viewModel.advance()
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.displayName)
                                .font(.custom("Inter", size: 18, relativeTo: .body).weight(.semibold))
                                .foregroundStyle(Color.colomba.text.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 12)
                            if language == selectedLanguage {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.colomba.success)
                                    .imageScale(.large)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                        .background(Color.colomba.bg.card)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    language == selectedLanguage ? Color.colomba.primary : Color.colomba.border.hairline
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityIdentifier("onboarding.languagePicker.\(language.rawValue)")
                    .accessibilityLabel(
                        language == selectedLanguage
                            ? "\(language.displayName), currently selected"
                            : language.displayName
                    )
                    .accessibilityHint("Selects \(language.displayName) and continues")
                }
            }

            Button {
                viewModel.back()
            } label: {
                Text(copy.languageBack)
                    .font(.custom("Inter", size: 16, relativeTo: .body).weight(.semibold))
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("onboarding.languagePicker.back")
            .accessibilityLabel(copy.languageBack)
            .accessibilityHint("Returns to welcome")
        }
        .padding(28)
        .frame(maxWidth: 620, maxHeight: .infinity, alignment: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
    }
}
