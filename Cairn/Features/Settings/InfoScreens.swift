import SwiftUI

// MARK: - Shared scaffolding for About / Privacy / Terms
//
// These three screens share a header, scroll layout, and typographic rhythm.
// Rather than repeat that three times, they're built from small shared pieces
// here. Each screen stays a thin definition of its own content.
//
// Privacy and Terms also mirror what's published at:
//   https://izbassar.dev/cairn/privacy
//   https://izbassar.dev/cairn/terms
// The in-app copy is the source of truth shown offline; the web pages exist
// because App Store Connect requires a public Privacy Policy URL.

// MARK: Reusable header

struct InfoScreenHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Settings")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color.accentSage)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.bgSecondary))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            Spacer()
            Text(title)
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 64, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }
}

// MARK: Reusable title block (big serif + accent word)

struct InfoTitleBlock: View {
    let lead: String
    let accent: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(lead)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text(accent)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
            }
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: Reusable text section (heading + body paragraphs)

struct InfoSection: View {
    let heading: String
    let paragraphs: [String]

    init(_ heading: String, _ paragraphs: [String]) {
        self.heading = heading
        self.paragraphs = paragraphs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(heading)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, p in
                Text(p)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }
}

// MARK: "View online" link row

struct InfoOnlineLink: View {
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(spacing: 6) {
                    Image(systemName: "safari")
                        .font(.system(size: 13, weight: .semibold))
                    Text("View online")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.accentSage)
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Color.accentSage.opacity(0.12))
                )
            }
        }
    }
}

// MARK: Footer line (last updated + contact)

struct InfoFooter: View {
    let lastUpdated: String
    var contact: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            if let contact {
                Text(contact)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            Text("Last updated \(lastUpdated)")
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sm)
    }
}

// MARK: - Shared constants

enum CairnInfo {
    static let developer = "Izbassar Orynbassar"
    static let contactEmail = "izbassar.orynbassar@icloud.com"
    static let privacyURL = "https://izbassar.dev/cairn/privacy"
    static let termsURL = "https://izbassar.dev/cairn/terms"
    /// Update when you change the legal copy. Keep in sync with the web pages.
    static let legalLastUpdated = "May 2026"
}
