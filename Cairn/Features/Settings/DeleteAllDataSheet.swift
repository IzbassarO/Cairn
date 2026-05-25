import SwiftUI
import SwiftData

// MARK: - DeleteAllDataSheet
//
// Irreversible local wipe. Because there's no cloud backup in v1, this is the
// one destructive action that deserves real friction: a typed confirmation.
// Offers an export shortcut first ("want a copy?").

struct DeleteAllDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query private var habits: [Habit]
    @Query private var moods: [MoodLog]

    /// Called after a successful wipe so the parent can route to export, etc.
    var onExportRequest: (() -> Void)? = nil

    @State private var confirmText = ""
    @FocusState private var fieldFocused: Bool

    private let confirmWord = "delete"

    var body: some View {
        VStack(spacing: 0) {
            grabber
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    icon
                    titleBlock
                    loseCard
                    confirmField
                    exportHint
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            actions
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDragIndicator(.hidden)
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.textTertiary.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
    }

    private var icon: some View {
        ZStack {
            Circle().fill(Color.accentCoral.opacity(0.15)).frame(width: 64, height: 64)
            Image(systemName: "trash")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentCoral)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: Spacing.sm) {
            (Text("Delete ").foregroundStyle(Color.textPrimary)
             + Text("all data?").foregroundStyle(Color.accentCoral))
                .font(.system(size: 28, weight: .bold, design: .serif))
            Text(summaryLine)
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: You'll lose

    private var loseCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("YOU'LL LOSE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.textTertiary)

            loseRow(icon: "camera.macro", title: "\(totalStones) \(totalStones == 1 ? "stone" : "stones")", detail: sinceDetail)
            if habitCount > 0 {
                loseRow(icon: "leaf.fill", title: "\(habitCount) \(habitCount == 1 ? "habit" : "habits")", detail: habitNames)
            }
            if noteCount > 0 {
                loseRow(icon: "book", title: "\(noteCount) reflection \(noteCount == 1 ? "note" : "notes")", detail: nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.accentCoral.opacity(0.08))
        )
    }

    private func loseRow(icon: String, title: String, detail: String?) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentCoral.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentCoral)
            }
            Group {
                if let detail {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.textPrimary)
                    + Text(" · \(detail)").font(.system(size: 15)).foregroundStyle(Color.textSecondary)
                } else {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.textPrimary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Confirm field

    private var confirmField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TO CONFIRM, TYPE \"DELETE\"")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.textTertiary)
            TextField("delete", text: $confirmText)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .fill(Color.bgSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .strokeBorder(canDelete ? Color.accentSage : Color.bgTertiary, lineWidth: 1.5)
                        )
                )
        }
    }

    private var exportHint: some View {
        Button {
            dismiss()
            onExportRequest?()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13))
                (Text("Want a copy first? You can ").font(.system(size: 13))
                 + Text("export").font(.system(size: 13, weight: .semibold))
                 + Text(" before deleting.").font(.system(size: 13)))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.accentSage)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.accentSage.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: performDelete) {
                Text("Delete all data — forever")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                            .fill(canDelete ? Color.accentCoral : Color.accentCoral.opacity(0.4))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canDelete)

            Button("Cancel") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(Color.bgPrimary)
    }

    // MARK: Logic

    private var canDelete: Bool {
        confirmText.trimmingCharacters(in: .whitespaces).lowercased() == confirmWord
    }

    private func performDelete() {
        guard canDelete else { return }
        // Wipe every habit (logs cascade-delete) and every mood log.
        for habit in habits {
            NotificationService.shared.cancel(habitId: habit.id)
            context.delete(habit)
        }
        for mood in moods {
            context.delete(mood)
        }
        try? context.save()
        dismiss()
    }

    // MARK: Derived

    private var habitCount: Int { habits.count }
    private var totalStones: Int { habits.reduce(0) { $0 + ($1.logs?.count ?? 0) } }
    private var noteCount: Int {
        habits.reduce(0) { acc, h in
            acc + (h.logs ?? []).filter { ($0.note ?? "").isEmpty == false }.count
        }
    }

    private var summaryLine: String {
        var parts: [String] = []
        parts.append("all \(habitCount) \(habitCount == 1 ? "habit" : "habits")")
        parts.append("all \(totalStones) \(totalStones == 1 ? "stone" : "stones")")
        if noteCount > 0 { parts.append("\(noteCount) reflection \(noteCount == 1 ? "note" : "notes")") }
        let list = parts.joined(separator: ", ")
        return "This will remove \(list). It can't be undone."
    }

    private var sinceDetail: String? {
        let earliest = habits.flatMap { $0.logs ?? [] }.map(\.loggedAt).min()
        guard let earliest else { return nil }
        let f = DateFormatter(); f.dateFormat = "MMMM d"
        return "placed since \(f.string(from: earliest))"
    }

    private var habitNames: String {
        let names = habits.sorted { $0.sortOrder < $1.sortOrder }.map(\.name)
        return names.prefix(4).joined(separator: ", ")
    }
}
