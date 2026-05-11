import SwiftUI

struct IconPickerSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 64, maximum: 80), spacing: Spacing.sm)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(HabitIconLibrary.all, id: \.self) { icon in
                        iconCell(icon)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Choose icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = selected == icon
        return Button {
            withAnimation(.spring(response: 0.25)) { selected = icon }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { dismiss() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(isSelected ? Color.accentSage.opacity(0.18) : Color.bgSecondary)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .strokeBorder(Color.accentSage, lineWidth: 2)
                        }
                    }
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.accentSage : Color.textSecondary)
            }
            .aspectRatio(1, contentMode: .fit)
            .sensoryFeedback(.selection, trigger: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.replacingOccurrences(of: ".", with: " "))
    }
}

enum HabitIconLibrary {
    static let all: [String] = [
        // Health & body
        "heart.fill", "drop.fill", "pills.fill", "fork.knife", "leaf.fill",
        "figure.walk", "figure.run", "figure.yoga", "dumbbell.fill", "bicycle",
        // Mind
        "brain.head.profile", "book.fill", "sparkles", "lightbulb.fill", "music.note",
        // Time & routine
        "clock.fill", "alarm.fill", "timer", "calendar",
        // Sleep
        "bed.double.fill", "moon.zzz.fill", "moon.stars.fill",
        // Focus
        "target", "eye.fill", "checkmark.circle.fill",
        // Care
        "bathtub.fill", "hands.sparkles.fill", "shower.fill",
        // Daily life
        "house.fill", "phone.fill", "envelope.fill",
        "pawprint.fill", "cart.fill", "creditcard.fill"
    ]
}
