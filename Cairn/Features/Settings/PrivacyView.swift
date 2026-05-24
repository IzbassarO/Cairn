import SwiftUI

struct PrivacyView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    private func close() { if let onClose { onClose() } else { dismiss() } }

    var body: some View {
        VStack(spacing: 0) {
            InfoScreenHeader(title: "Privacy", onClose: close)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    InfoTitleBlock(
                        lead: "Your data",
                        accent: "stays here.",
                        subtitle: "Cairn is built to keep everything on your device. The short version: we don't collect it."
                    )

                    highlightCard

                    InfoSection("What Cairn stores", [
                        "Your habits, the stones you place, your reminder times, your name and your \"why\", and your settings.",
                        "All of it lives locally on your device using Apple's on-device storage. It is not uploaded to us, because we don't run a server that receives it."
                    ])

                    InfoSection("What we collect", [
                        "Nothing. Cairn has no analytics, no advertising, and no third-party tracking. We don't have accounts, and we don't ask you to sign in.",
                        "Because we never receive your data, we can't see it, sell it, or share it."
                    ])

                    InfoSection("Notifications", [
                        "If you turn on reminders, Cairn schedules them locally through iOS. The reminder content stays on your device — it isn't sent anywhere.",
                        "You can pause or turn off notifications at any time in Settings."
                    ])

                    InfoSection("Your control", [
                        "You can edit or delete any habit, and you can remove all of your data from inside the app at any time.",
                        "Deleting the app from your device also removes the data stored on it."
                    ])

                    InfoSection("Children", [
                        "Cairn is a general-audience app and is not directed at children under 13. It does not knowingly collect any personal information from anyone."
                    ])

                    InfoSection("Changes", [
                        "If a future version of Cairn ever adds something that handles data differently — for example optional crash reports or iCloud sync — this policy will be updated before that feature ships, and the change will be explained in plain language."
                    ])

                    InfoSection("Contact", [
                        "Questions about privacy? Reach out at \(CairnInfo.contactEmail)."
                    ])

                    InfoOnlineLink(urlString: CairnInfo.privacyURL)

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

    private var highlightCard: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.accentSage)
            VStack(alignment: .leading, spacing: 4) {
                Text("No collection, no tracking")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Cairn works fully offline. Your habits never leave your device.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentSage.opacity(0.12))
        )
    }
}
