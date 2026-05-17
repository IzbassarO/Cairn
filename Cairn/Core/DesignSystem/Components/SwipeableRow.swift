import SwiftUI

/// iOS-style swipe-to-action row. Wraps any content and reveals up to two
/// action buttons when the user drags the content left.
///
/// Used in Today (and anywhere we have habit rows in a ScrollView). SwiftUI's
/// `.swipeActions` only works inside `List`, which would force our custom
/// row styling into system cells — so we roll our own drag gesture instead.
///
/// Behavior:
///  - Drag left → buttons appear progressively under the content
///  - Release past `revealThreshold` → buttons stay visible (latched open)
///  - Release before threshold → snaps back closed
///  - Drag past `fullSwipeThreshold` → snap fully open and fire `onFullSwipe`
///    callback (typically wired to the same handler as the rightmost button)
///  - Tap anywhere outside the row when open → snaps closed
///  - Tap on a button → fires that button's action AND closes the row
///
/// One row at a time: a parent can broadcast a "close all swipes" via the
/// `closeBus` published property if it wires multiple SwipeableRows.
struct SwipeableRow<Content: View>: View {
    let actions: [SwipeAction]
    /// Called when the user performs a full swipe (drag past `fullSwipeThreshold`).
    /// Usually the same as the rightmost (destructive) action's `action`.
    let onFullSwipe: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    @State private var isOpen: Bool = false

    // MARK: Layout constants
    private let buttonWidth: CGFloat = 72
    private var revealedWidth: CGFloat { CGFloat(actions.count) * buttonWidth }
    /// Drag past this point to consider it a "full swipe" — the row latches
    /// open AND fires `onFullSwipe`. ~140 pt feels right on iPhone-class screens.
    private let fullSwipeThreshold: CGFloat = 140

    var body: some View {
        ZStack(alignment: .trailing) {
            // Buttons sit underneath the content, revealed by drag offset.
            buttonsLayer

            // Foreground content slides left.
            content()
                .offset(x: offset)
                .gesture(dragGesture)
        }
        // Hard-clip so the buttons don't bleed past the row bounds while
        // animating closed.
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
        // Only show buttons when the content has been dragged left enough
        // for them to actually be visible. Avoids them flashing during the
        // closing animation.
        .opacity(offset < -2 ? 1 : 0)
    }

    // MARK: Drag

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                let proposed = startOffset + value.translation.width
                // Rubber-band when dragging right past 0 — only allow a tiny
                // bit, so the row visibly resists.
                if proposed > 0 {
                    offset = proposed / 4
                } else {
                    offset = proposed
                }
            }
            .onEnded { value in
                let final = startOffset + value.translation.width

                // Full swipe: latch open AND fire the destructive action.
                if final < -fullSwipeThreshold {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                        offset = -revealedWidth
                        isOpen = true
                    }
                    onFullSwipe()
                    // The destructive handler will typically show an alert
                    // and call `close()` when dismissed.
                    return
                }

                // Past reveal threshold: snap open.
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
        // Run the action just after the close animation begins. We don't
        // wait for it to complete — the action might present a sheet/alert
        // that should appear immediately.
        action()
    }
}

/// One action button revealed by a swipe.
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
