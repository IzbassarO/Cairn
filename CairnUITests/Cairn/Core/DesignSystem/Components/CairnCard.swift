import SwiftUI

struct CairnCard<Content: View>: View {
    var padding: CGFloat = Spacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.bgSecondary)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
