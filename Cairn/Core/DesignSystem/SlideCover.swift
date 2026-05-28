import SwiftUI

// MARK: - Slide (horizontal push) presentation
//
// A reusable full-screen presentation that enters from the trailing edge and
// exits back to the trailing edge — the "push" feel of Instagram / WhatsApp.
//
// Unlike NavigationStack, this is driven ONLY by button taps: there is no
// interactive edge-swipe to dismiss. Open and close both animate horizontally
// and only happen when code flips the binding (i.e. when a button is tapped).
//
// Use this for "drilling deeper" (settings detail screens, Add another,
// Calendar, Notifications, Profile → Edit). Keep the system `.fullScreenCover`
// for things that should feel like modals rising from the bottom (creating a
// habit via the row, pickers, View Garden, the habit list).
//
// IMPORTANT: presented views are NOT inside a system presenter, so
// `@Environment(\.dismiss)` does NOT work here. Dismiss by setting the binding
// from the presented view's own button — pass it a close callback:
//
//   .slideCover(isPresented: $showProfile) {
//       ProfileView(onDismiss: { showProfile = false })
//   }
//
// The whole cover (header, back button, content) moves as ONE layer via a
// single animated `offset`, so nothing lags behind during the transition.

extension View {
    /// Presents `content` with a horizontal slide-in/out, gated on a Bool.
    func slideCover<Cover: View>(
        isPresented: Binding<Bool>,
        animation: Animation = SlideCover.defaultAnimation,
        @ViewBuilder content: @escaping () -> Cover
    ) -> some View {
        modifier(SlideCoverBoolModifier(isPresented: isPresented,
                                        animation: animation,
                                        cover: content))
    }

    /// Presents `content` with a horizontal slide-in/out, gated on an optional
    /// Identifiable item (mirrors `fullScreenCover(item:)`).
    func slideCover<Item: Identifiable, Cover: View>(
        item: Binding<Item?>,
        animation: Animation = SlideCover.defaultAnimation,
        @ViewBuilder content: @escaping (Item) -> Cover
    ) -> some View {
        modifier(SlideCoverItemModifier(item: item,
                                        animation: animation,
                                        cover: content))
    }
}

enum SlideCover {
    /// Snappy but smooth — close to a native push, intentionally quick.
    static let defaultAnimation: Animation = .timingCurve(0.32, 0.72, 0, 1, duration: 0.34)
}

// MARK: - Bool-driven modifier

private struct SlideCoverBoolModifier<Cover: View>: ViewModifier {
    @Binding var isPresented: Bool
    let animation: Animation
    @ViewBuilder let cover: () -> Cover

    /// Drives the offset. Decoupled from `isPresented` so the OUTGOING content
    /// stays mounted while it slides off, then unmounts when offset settles.
    @State private var visible = false
    /// Keeps the cover mounted during the close animation.
    @State private var mounted = false

    func body(content: Content) -> some View {
        GeometryReader { geo in
            ZStack {
                content

                if mounted {
                    cover()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .background(Color.bgPrimary.ignoresSafeArea())
                        // Hide the parent TabView's tab bar while we're shown,
                        // so drill-in screens read as their own surface.
                        .toolbar(.hidden, for: .tabBar)
                        // Single offset for the WHOLE cover → moves as one unit.
                        .offset(x: visible ? 0 : geo.size.width)
                        .zIndex(1)
                }
            }
        }
        .onAppear { syncMountState() }
        .onChange(of: isPresented) { _, _ in syncMountState() }
    }

    private func syncMountState() {
        if isPresented {
            // Mount off-screen, then animate in next runloop tick.
            mounted = true
            visible = false
            DispatchQueue.main.async {
                withAnimation(animation) { visible = true }
            }
        } else if mounted {
            // Animate out, then unmount once it's fully off-screen.
            withAnimation(animation) { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if !isPresented { mounted = false }
            }
        }
    }
}

// MARK: - Item-driven modifier

private struct SlideCoverItemModifier<Item: Identifiable, Cover: View>: ViewModifier {
    @Binding var item: Item?
    let animation: Animation
    @ViewBuilder let cover: (Item) -> Cover

    @State private var visible = false
    /// Held separately so the outgoing view keeps its data while sliding off.
    @State private var heldItem: Item?

    func body(content: Content) -> some View {
        GeometryReader { geo in
            ZStack {
                content

                if let value = heldItem {
                    cover(value)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .background(Color.bgPrimary.ignoresSafeArea())
                        .toolbar(.hidden, for: .tabBar)
                        .offset(x: visible ? 0 : geo.size.width)
                        .zIndex(1)
                }
            }
        }
        .onAppear { syncMountState() }
        .onChange(of: item?.id) { _, _ in syncMountState() }
    }

    private func syncMountState() {
        if let current = item {
            heldItem = current
            visible = false
            DispatchQueue.main.async {
                withAnimation(animation) { visible = true }
            }
        } else if heldItem != nil {
            withAnimation(animation) { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if item?.id == nil { heldItem = nil }
            }
        }
    }
}
