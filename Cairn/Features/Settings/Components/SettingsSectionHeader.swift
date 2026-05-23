import SwiftUI

struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.textPrimary)
            .padding(.leading, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, 6)
    }
}
