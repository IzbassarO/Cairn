import SwiftUI

/// Shared top block for the Today tab. Used both on the first-time welcome
/// screen and on the returning-user screen — same look, same spacing.
///
/// Greeting changes by time of day (Good morning / Good afternoon / Good
/// evening / Hello late). Name is italicised and tinted sage. The two trailing
/// circle buttons are decorative in v1.0 (calendar, bell).
struct TodayHeader: View {
    @AppStorage("userDisplayName") private var displayName: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLine)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                Text(greeting + ",")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(displayedName)
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.accentSage)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: Spacing.sm)

            HStack(spacing: Spacing.sm) {
                topBarButton(icon: "calendar")
                topBarButton(icon: "bell")
            }
            .padding(.top, 4)
        }
    }

    // MARK: Date line

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: .now)
    }

    // MARK: Greeting

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello, late one"
        }
    }

    // MARK: Name

    private var displayedName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "friend." : "\(trimmed)."
    }

    // MARK: Top-bar buttons (decorative in v1.0)

    private func topBarButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.accentSage)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.bgSecondary))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .accessibilityHidden(true)
    }
}
