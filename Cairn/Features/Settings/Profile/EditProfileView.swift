import SwiftUI

struct EditProfileView: View {
    let onDismiss: () -> Void

    @AppStorage("userDisplayName") private var displayName: String = ""
    @AppStorage("userWhy") private var userWhy: String = ""
    @AppStorage("userWhySetDate") private var whySetDateRaw: Double = 0

    @State private var nameDraft: String = ""
    @State private var whyDraft: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case name, why }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    avatarPreview
                    nameSection
                    whySection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .onAppear {
            nameDraft = displayName
            whyDraft = userWhy
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button(action: cancel) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.bgSecondary))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            Spacer()
            Text("Edit profile")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button(action: save) {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentSage))
                    .shadow(color: Color.accentSage.opacity(0.3), radius: 4, y: 2)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Avatar preview

    private var avatarPreview: some View {
        ProfileAvatar(name: nameDraft, size: 84)
            .padding(.top, Spacing.sm)
            .animation(.easeOut(duration: 0.15), value: firstLetterOf(nameDraft))
    }

    // MARK: Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            fieldLabel("DISPLAY NAME", icon: "person")
            TextField("Friend", text: $nameDraft)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color.textPrimary)
                .focused($focusedField, equals: .name)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Color.bgSecondary)
                )
            Text("This is what you'll see when you open Cairn.")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
                .padding(.leading, 2)
        }
    }

    // MARK: Your why

    private var whySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            fieldLabel("YOUR WHY", icon: "quote.opening")

            VStack(alignment: .leading, spacing: Spacing.md) {
                TextField(
                    "The reason you're here…",
                    text: $whyDraft,
                    axis: .vertical
                )
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(3)
                .lineLimit(3...6)
                .focused($focusedField, equals: .why)

                HStack {
                    inspireButton
                    Spacer()
                    if !whyDraft.isEmpty {
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { whyDraft = "" }
                        } label: {
                            Text("Clear")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )

            Text("Short and personal beats grand. You can change it anytime.")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
                .padding(.leading, 2)
        }
    }

    private var inspireButton: some View {
        Button {
            focusedField = nil
            withAnimation(.easeInOut(duration: 0.2)) {
                whyDraft = ProfileWhyPrompts.random(excluding: whyDraft)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text(whyDraft.isEmpty ? "Inspire me" : "Try another")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.accentSage)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.accentSage.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }

    private func fieldLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.accentSage)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.leading, 2)
    }

    // MARK: Actions

    private func save() {
        let newWhy = whyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldWhy = userWhy.trimmingCharacters(in: .whitespacesAndNewlines)
        if newWhy != oldWhy {
            whySetDateRaw = newWhy.isEmpty ? 0 : Date().timeIntervalSince1970
        }
        displayName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        userWhy = newWhy
        focusedField = nil
        onDismiss()
    }

    private func cancel() {
        focusedField = nil
        onDismiss()
    }

    private func firstLetterOf(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
    }
}
