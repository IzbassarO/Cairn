import SwiftUI
import SwiftData

struct ProfileView: View {
    /// Parent-owned dismissal so present and dismiss can both skip animation.
    let onDismiss: () -> Void

    @AppStorage("userDisplayName") private var displayName: String = ""
    @AppStorage("userWhy") private var userWhy: String = ""

    /// Local stamp for "Cairn since" on a fresh install with no habits yet.
    @AppStorage("cairnJoinDate") private var joinDateRaw: Double = 0
    /// Stamped by EditProfileView whenever the why text changes.
    @AppStorage("userWhySetDate") private var whySetDateRaw: Double = 0

    @Query private var habits: [Habit]

    @State private var showEdit = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    hero
                    whyCard
                    gardenCard
                    closingNote
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .onAppear {
            if joinDateRaw == 0 { joinDateRaw = Date().timeIntervalSince1970 }
        }
        .slideCover(isPresented: $showEdit) {
            EditProfileView(onDismiss: { showEdit = false })
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            backButton
            Spacer()
            Text("Profile")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color.textPrimary)
            Spacer()
            editButton
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    private var backButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Color.accentSage)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.bgSecondary))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }

    private var editButton: some View {
        Button {
            showEdit = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                Text("Edit")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.accentSage))
            .shadow(color: Color.accentSage.opacity(0.3), radius: 4, y: 2)
        }
    }

    // MARK: Hero

    private var hero: some View {
        HStack(spacing: Spacing.md) {
            ProfileAvatar(name: displayName, size: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text(displayedName)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 5) {
                    Text("Cairn since")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                    Text(joinDateString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                cairnFreePill
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
    }

    private var cairnFreePill: some View {
        HStack(spacing: 5) {
            Image(systemName: "leaf")
                .font(.system(size: 11, weight: .semibold))
            Text("CAIRN FREE")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
        }
        .foregroundStyle(Color.accentSage)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.accentSage.opacity(0.15)))
    }

    // MARK: Your why

    private var whyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentSage)
                Text("YOUR \"WHY\"")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            if trimmedWhy.isEmpty {
                Text("The reason you're here. One honest sentence you'll see when things feel heavy.")
                    .font(.system(size: 17, design: .serif))
                    .italic()
                    .foregroundStyle(Color.textTertiary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("\"\(trimmedWhy)\"")
                        .font(.system(size: 22, design: .serif))
                        .italic()
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                        Text(whyMetaString)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Your garden

    private var gardenCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR GARDEN")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentSage)
                        .tracking(0.5)
                    Text("\(totalStones) \(totalStones == 1 ? "stone" : "stones"), gently placed.")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.sm)
                cairnStack
            }

            Divider()
                .overlay(Color.bgTertiary)
                .padding(.vertical, Spacing.md)

            HStack(spacing: 0) {
                gardenStat(value: "\(activeDays)", label: "active days")
                statDivider
                gardenStat(value: "\(activeHabitCount)", label: activeHabitCount == 1 ? "habit" : "habits")
                statDivider
                gardenStat(value: "\(weeksHere)", label: weeksHere == 1 ? "week here" : "weeks here")
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Color.bgSecondary)
        )
    }

    private func gardenStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.bgTertiary)
            .frame(width: 1, height: 34)
    }

    /// A small stacked-stones cairn drawn with shapes (no asset needed).
    private var cairnStack: some View {
        VStack(spacing: -2) {
            Ellipse()
                .fill(Color.textTertiary.opacity(0.55))
                .frame(width: 26, height: 13)
            Ellipse()
                .fill(Color.accentSage)
                .frame(width: 44, height: 18)
            Ellipse()
                .fill(Color.accentSage.opacity(0.35))
                .frame(width: 34, height: 15)
            Ellipse()
                .fill(Color.textTertiary.opacity(0.4))
                .frame(width: 52, height: 19)
        }
        .padding(.top, 2)
    }

    // MARK: Closing note

    /// A soft, data-aware line so the screen feels finished rather than cut off.
    private var closingNote: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf")
                .font(.system(size: 14))
                .foregroundStyle(Color.accentSage.opacity(0.8))
            Text(closingLine)
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.sm)
    }

    private var closingLine: String {
        switch totalStones {
        case 0:      return "Every cairn starts with one stone. Yours is waiting."
        case 1..<10: return "A few stones in. This is how paths begin."
        default:     return "One stone at a time, gently. Keep going."
        }
    }

    // MARK: Derived

    private var trimmedWhy: String {
        userWhy.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    private var activeHabits: [Habit] { habits.filter { !$0.isArchived } }
    private var activeHabitCount: Int { activeHabits.count }
    private var totalStones: Int { activeHabits.totalStones }
    private var activeDays: Int { activeHabits.uniqueLogDayCount }

    /// Real "since" date: earliest habit's createdAt, falling back to the
    /// locally stamped join date (covers a fresh install with no habits yet).
    private var joinDate: Date {
        let earliest = habits.map(\.createdAt).filter { $0 > .distantPast }.min()
        if let earliest { return earliest }
        return joinDateRaw == 0 ? Date() : Date(timeIntervalSince1970: joinDateRaw)
    }

    private var weeksHere: Int {
        let days = Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
        return max(1, days / 7 + 1)
    }

    private var joinDateString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: joinDate)
    }

    private var whyMetaString: String {
        whySetDateRaw == 0 ? "Tap to revisit" : "Set \(whyAgeString) · Tap to revisit"
    }

    private var whyAgeString: String {
        guard whySetDateRaw != 0 else { return "just now" }
        return Self.relativeAge(from: Date(timeIntervalSince1970: whySetDateRaw))
    }

    static func relativeAge(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
        if let y = c.year, y >= 1 { return y == 1 ? "1 year ago" : "\(y) years ago" }
        if let m = c.month, m >= 1 { return m == 1 ? "1 month ago" : "\(m) months ago" }
        if let d = c.day, d >= 1 { return d == 1 ? "yesterday" : "\(d) days ago" }
        return "today"
    }
}
