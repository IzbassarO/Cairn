import SwiftUI

struct TermsView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    private func close() { if let onClose { onClose() } else { dismiss() } }

    var body: some View {
        VStack(spacing: 0) {
            InfoScreenHeader(title: "Terms", onClose: close)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    InfoTitleBlock(
                        lead: "The simple",
                        accent: "agreement.",
                        subtitle: "Plain-language terms for using Cairn. By using the app, you agree to these."
                    )

                    InfoSection("Using Cairn", [
                        "Cairn is provided for your personal, non-commercial use. You're free to use it to build and track your own habits.",
                        "Please don't copy, resell, reverse-engineer, or attempt to break the app or its security."
                    ])

                    InfoSection("Not medical advice", [
                        "Cairn supports habit-building. It is not a medical device, and it does not provide medical, psychological, or therapeutic advice.",
                        "Its content — including any coaching tips — is for general support only. For health decisions, talk to a qualified professional."
                    ])

                    InfoSection("Your content", [
                        "The habits, notes, and other things you create in Cairn belong to you. Because they're stored on your device, you are responsible for them — including keeping your own backups if you wish."
                    ])

                    InfoSection("Availability", [
                        "Cairn is offered \"as is\" and \"as available.\" We work to keep it stable and pleasant, but we can't promise it will always be error-free or uninterrupted.",
                        "To the extent allowed by law, the developer isn't liable for any loss arising from use of the app, including loss of data stored on your device."
                    ])

                    InfoSection("Apple's terms", [
                        "Cairn is distributed through the App Store, so Apple's standard Licensed Application End User License Agreement also applies to your use of the app."
                    ])

                    InfoSection("Changes", [
                        "These terms may be updated as Cairn grows. Significant changes will be reflected here and on the web version before they take effect."
                    ])

                    InfoSection("Contact", [
                        "Questions about these terms? Reach out at \(CairnInfo.contactEmail)."
                    ])

                    InfoOnlineLink(urlString: CairnInfo.termsURL)

                    InfoFooter(
                        lastUpdated: CairnInfo.legalLastUpdated,
                        contact: "\(CairnInfo.developer) · \(CairnInfo.contactEmail)"
                    )
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }
}
