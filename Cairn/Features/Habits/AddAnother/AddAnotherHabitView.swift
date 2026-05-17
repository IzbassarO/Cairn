import SwiftUI
import SwiftData

/// N1 — Add Another Habit screen. Full-screen library of templates with
/// search, category filter, optional Coach Pairing suggestion, and a fallback
/// to the Custom Habit screen (F7).
///
/// Flow:
///  1. User browses templates (filtered by chips + search)
///  2. Tapping `+` on a row → N2 (ConfigureHabitView) for that template
///  3. Tapping "Add this pairing" on Coach Pairing card → N2 with pairingAnchor set
///  4. Tapping "+ Write a custom habit" → F7 (CustomHabitView)
///
/// Saving in N2 or F7 dismisses both that view and N1 in sequence.
struct AddAnotherHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    /// Called when a habit is successfully saved through any of N1's paths.
    /// HomeView uses this to dismiss N1 and schedule notifications.
    let onPlanted: (Habit) -> Void

    @State private var searchText: String = ""
    @State private var selectedCategories: Set<HabitCategory> = []

    /// Pre-filled template + optional pairing anchor for ConfigureHabitView.
    @State private var pendingTemplate: PendingTemplate?

    /// Trigger for F7 (custom).
    @State private var showCustom = false

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    private var pairing: CoachPairing? { CoachPairings.suggest(for: activeHabits) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    pitchBlock
                    searchField
                    AreasOfLifeChips(selected: $selectedCategories)
                        .padding(.horizontal, -Spacing.md) // bleed to edges
                    if let pairing {
                        CoachPairingCard(pairing: pairing) {
                            pendingTemplate = PendingTemplate(
                                template: pairing.suggestedTemplate,
                                anchor: pairing.anchorHabit
                            )
                        }
                    }
                    templatesList
                    customHabitFooter
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .fullScreenCover(item: $pendingTemplate) { pending in
            ConfigureHabitView(
                template: pending.template,
                pairingAnchor: pending.anchor
            ) { habit in
                // After N2 saves, hand the habit up to HomeView and let it
                // dismiss N1 as well.
                pendingTemplate = nil
                onPlanted(habit)
            }
        }
        .fullScreenCover(isPresented: $showCustom) {
            CustomHabitView { habit in
                showCustom = false
                onPlanted(habit)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.bgSecondary))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
            .accessibilityLabel("Close")

            Spacer()

            Text("New habit")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            // Invisible placeholder to keep the title centered.
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: Pitch block

    private var pitchBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(habitCountEyebrow)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.accentSage)
                .tracking(1.4)

            Text("What's the")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text("next small thing?")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.accentSage)
        }
    }

    private var habitCountEyebrow: String {
        let count = activeHabits.count
        switch count {
        case 0: return "YOUR FIRST HABIT"  // unreachable normally
        case 1: return "YOU HAVE 1 HABIT"
        default: return "YOU HAVE \(count) HABITS"
        }
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textTertiary)
            TextField("", text: $searchText, prompt:
                Text("Search habits or write your own...")
                    .foregroundStyle(Color.textTertiary)
            )
            .font(.system(size: 15))
            .foregroundStyle(Color.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    // MARK: Templates list

    private var templatesList: some View {
        let grouped = groupedTemplates
        return VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(grouped, id: \.category) { group in
                sectionHeader(for: group)
                VStack(spacing: Spacing.sm) {
                    ForEach(group.templates, id: \.id) { template in
                        TemplateLibraryRow(template: template) {
                            pendingTemplate = PendingTemplate(template: template, anchor: nil)
                        }
                    }
                }
            }

            if grouped.isEmpty {
                emptySearchState
            }
        }
    }

    private func sectionHeader(for group: TemplateGroup) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(group.title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text("All \(group.totalInCategory)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.top, Spacing.sm)
    }

    private var emptySearchState: some View {
        VStack(spacing: Spacing.sm) {
            Text("Nothing matches.")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Color.textSecondary)
            Text("Try a different word, or write your own below.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    // MARK: Custom footer

    private var customHabitFooter: some View {
        Button {
            showCustom = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("Write a custom habit")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.accentSage)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(
                        Color.accentSage.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Color.accentSage.opacity(0.06))
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.md)
    }

    // MARK: Filtering & grouping

    /// One section per category in `selectedCategories`. If selection is empty,
    /// returns all categories that have at least one matching template.
    private struct TemplateGroup {
        let category: HabitCategory
        let title: String
        let templates: [HabitTemplate]
        /// Total templates in this category (ignoring current search).
        /// Powers the "All N" label on the right of section headers.
        let totalInCategory: Int
    }

    private var groupedTemplates: [TemplateGroup] {
        let allTemplates = HabitTemplates.all

        // Apply search filter first (case-insensitive substring on name or cue).
        let searchFiltered: [HabitTemplate]
        let trimmed = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.isEmpty {
            searchFiltered = allTemplates
        } else {
            searchFiltered = allTemplates.filter { t in
                t.name.lowercased().contains(trimmed)
                    || (t.cue?.lowercased().contains(trimmed) ?? false)
            }
        }

        // Determine which categories to render.
        let categoriesToShow: [HabitCategory]
        if selectedCategories.isEmpty {
            // Show every category that has at least one (filtered) template,
            // in the natural HabitCategory order.
            let presentCategories = Set(searchFiltered.map(\.category))
            categoriesToShow = HabitCategory.allCases.filter { presentCategories.contains($0) }
        } else {
            categoriesToShow = HabitCategory.allCases.filter { selectedCategories.contains($0) }
        }

        return categoriesToShow.compactMap { category in
            let filteredInCategory = searchFiltered.filter { $0.category == category }
            guard !filteredInCategory.isEmpty else { return nil }
            let totalInCategory = allTemplates.filter { $0.category == category }.count
            return TemplateGroup(
                category: category,
                title: "In \(label(for: category))",
                templates: filteredInCategory,
                totalInCategory: totalInCategory
            )
        }
    }

    private func label(for category: HabitCategory) -> String {
        switch category {
        case .meds: return "Meds"
        case .water: return "Hydration"
        case .movement: return "Movement"
        case .focus: return "Focus"
        case .sleep: return "Sleep"
        case .transition: return "Transitions"
        case .hyperfocusCheckIn: return "Check-ins"
        case .custom: return "Other"
        }
    }
}

/// Small wrapper because `fullScreenCover(item:)` needs Identifiable.
struct PendingTemplate: Identifiable, Hashable {
    let id = UUID()
    let template: HabitTemplate
    let anchor: Habit?

    static func == (lhs: PendingTemplate, rhs: PendingTemplate) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
