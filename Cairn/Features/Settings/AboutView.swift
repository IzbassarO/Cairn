import SwiftUI

struct AboutView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    private func close() { if let onClose { onClose() } else { dismiss() } }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 0) {
            InfoScreenHeader(title: "About Cairn", onClose: close)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    hero

                    InfoTitleBlock(
                        lead: "Built to be",
                        accent: "gentle.",
                        subtitle: "Cairn is a calm place to build habits without shame or streak pressure."
                    )

                    InfoSection("The idea", [
                        "A cairn is a small stack of stones that marks a path. You add one stone at a time, and over many small placements a trail appears.",
                        "Cairn treats habits the same way. You're not chasing a perfect streak — you're placing one stone when you show up, and returning gently when you don't."
                    ])

                    InfoSection("Made for ADHD brains", [
                        "Most habit apps punish a missed day. That's exactly when an ADHD brain needs less pressure, not more.",
                        "Cairn is designed to work with how attention and motivation actually move: tiny steps, kind reminders, and an easy way back after a hard week."
                    ])

                    InfoSection("What Cairn won't do", [
                        "No guilt. No broken-streak shaming. No medical or therapy claims.",
                        "It's a supportive tool, not a doctor — and it stays on your side."
                    ])

                    versionCard

                    InfoFooter(
                        lastUpdated: CairnInfo.legalLastUpdated,
                        contact: "Made by \(CairnInfo.developer)"
                    )
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    private var hero: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.accentSage.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentSage)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Cairn")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("Gentle habit coach")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(.top, Spacing.sm)
    }

    private var versionCard: some View {
        HStack {
            Text("Version")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(appVersion)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }
}
