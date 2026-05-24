import SwiftUI

struct ProfileAvatar: View {
    let name: String
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentSage.opacity(0.78),
                            Color.accentSage
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.32), .clear],
                        center: .init(x: 0.3, y: 0.25),
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )

            Text(firstLetter)
                .font(.system(size: size * 26 / 60, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.bgPrimary)

            leafAccent
                .offset(x: size * 20 / 60, y: size * 20 / 60)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.accentSage.opacity(0.32), radius: size * 8 / 60, y: size * 3 / 60)
    }

    private var leafAccent: some View {
        ZStack {
            Circle()
                .fill(Color.bgPrimary)
                .frame(width: size * 22 / 60, height: size * 22 / 60)
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 10 / 60, weight: .bold))
                .foregroundStyle(Color.accentSage)
        }
    }

    private var firstLetter: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }
}
