import SwiftUI
import SwiftData

struct ExportDataView: View {
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]
    @Query private var moods: [MoodLog]

    @State private var format: ExportFormat = .csv
    @State private var shareURL: URL?
    @State private var exportError: String?

    private func close() { if let onClose { onClose() } else { dismiss() } }

    var body: some View {
        VStack(spacing: 0) {
            InfoScreenHeader(title: "Export data", onClose: close)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    titleBlock
                    includedCard
                    formatSection
                    exportButton
                    Text("Saved to Files · also shareable to Mail, AirDrop, or Notes.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .sheet(item: $shareURL) { url in
            ShareSheet(items: [url])
        }
        .alert("Couldn't export", isPresented: .constant(exportError != nil)) {
            Button("OK") { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TAKE IT WITH YOU")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.accentSage)
            Text("Your garden,")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text("in one neat file.")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.accentSage)
        }
    }

    // MARK: What's included

    private var includedCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("WHAT'S INCLUDED")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.accentSage)
            Text(includedSummary)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(Color.bgTertiary)

            HStack(spacing: 0) {
                stat(value: "\(totalStones)", label: totalStones == 1 ? "stone" : "stones")
                statDivider
                stat(value: "\(habitCount)", label: habitCount == 1 ? "habit" : "habits")
                statDivider
                stat(value: "\(noteCount)", label: noteCount == 1 ? "note" : "notes")
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle().fill(Color.bgTertiary).frame(width: 1, height: 32)
    }

    // MARK: Format

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("FORMAT")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.accentSage)
            VStack(spacing: 0) {
                ForEach(ExportFormat.allCases) { f in
                    formatRow(f)
                    if f != ExportFormat.allCases.last {
                        Divider().overlay(Color.bgTertiary).padding(.leading, 64)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
        }
    }

    private func formatRow(_ f: ExportFormat) -> some View {
        let selected = format == f
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { format = f }
        } label: {
            HStack(spacing: Spacing.md) {
                Text(f.badge)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.accentSage)
                    .frame(width: 44, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.accentSage.opacity(0.18))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(f.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(f.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(selected ? Color.clear : Color.textTertiary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if selected {
                        Circle().fill(Color.accentSage).frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.bgPrimary)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: Export button

    private var exportButton: some View {
        Button(action: runExport) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Export & share")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(Color.bgPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .fill(habitCount == 0 ? Color.accentSage.opacity(0.4) : Color.accentSage)
            )
        }
        .buttonStyle(.plain)
        .disabled(habitCount == 0)
    }

    private func runExport() {
        do {
            shareURL = try DataExportService.makeFile(habits: habits, moods: moods, format: format)
        } catch {
            exportError = error.localizedDescription
        }
    }

    // MARK: Derived

    private var habitCount: Int { habits.filter { !$0.isArchived }.count }
    private var totalStones: Int { habits.reduce(0) { $0 + ($1.logs?.count ?? 0) } }
    private var noteCount: Int {
        habits.reduce(0) { acc, h in
            acc + (h.logs ?? []).filter { ($0.note ?? "").isEmpty == false }.count
        }
    }

    private var includedSummary: String {
        let h = "\(habitCount) \(habitCount == 1 ? "habit" : "habits")"
        let s = "\(totalStones) \(totalStones == 1 ? "stone" : "stones")"
        let n = "\(noteCount) \(noteCount == 1 ? "note" : "notes")"
        return "\(h) · \(s) placed · \(n)."
    }
}

// MARK: - Share sheet bridge

/// Makes a URL Identifiable so it can drive `.sheet(item:)`.
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
