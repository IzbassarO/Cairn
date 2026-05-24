import SwiftUI

struct SwipeableRow<Content: View>: View {
    let actions: [SwipeAction]
    let onFullSwipe: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    @State private var isOpen: Bool = false

    // MARK: Layout constants
    private let buttonWidth: CGFloat = 72
    private var revealedWidth: CGFloat { CGFloat(actions.count) * buttonWidth }
    private let fullSwipeThreshold: CGFloat = 140

    var body: some View {
        ZStack(alignment: .trailing) {
            buttonsLayer

            content()
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .clipped()
    }

    // MARK: Buttons layer
    private var buttonsLayer: some View {
        HStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                Button {
                    closeAndFire(action.action)
                } label: {
                    VStack(spacing: 4) {
                        if let icon = action.icon {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(action.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth)
                    .frame(maxHeight: .infinity)
                    .background(action.tint)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(offset < -2 ? 1 : 0)
    }

    // MARK: Drag
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                let proposed = startOffset + value.translation.width
                if proposed > 0 {
                    offset = proposed / 4
                } else {
                    offset = proposed
                }
            }
            .onEnded { value in
                let final = startOffset + value.translation.width

                if final < -fullSwipeThreshold {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        offset = -revealedWidth
                        isOpen = true
                    }
                    onFullSwipe()
                    return
                }

                if final < -revealedWidth / 2 {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        offset = -revealedWidth
                        isOpen = true
                        startOffset = -revealedWidth
                    }
                } else {
                    // Otherwise: snap closed.
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        offset = 0
                        isOpen = false
                        startOffset = 0
                    }
                }
            }
    }

    // MARK: Programmatic close
    private func closeAndFire(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            offset = 0
            isOpen = false
            startOffset = 0
        }
        action()
    }
}

struct SwipeAction {
    let title: String
    let icon: String?
    let tint: Color
    let action: () -> Void

    init(title: String, icon: String? = nil, tint: Color, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.action = action
    }
}
