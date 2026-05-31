import SwiftUI
import Combine

// MARK: - Slide (horizontal push) presentation
//
// A reusable presentation that enters from the trailing edge and exits back
// to the trailing edge — the "push" feel of Instagram / WhatsApp.
//
// Architecture:
//   ┌─ SlideCoverHost (wraps the app root) ──────────────────┐
//   │  ┌─ your content (TabView, tabs, screens) ─────────┐   │
//   │  │  ↑ child views call `.slideCover(isPresented:)`  │   │
//   │  └──────────────────────────────────────────────────┘   │
//   │  ┌─ overlay layer (above everything, incl. tab bar) ─┐  │
//   │  │  ↑ this is where the cover actually renders       │  │
//   │  └───────────────────────────────────────────────────┘  │
//   └────────────────────────────────────────────────────────┘
//
// Why centralized: when the modifier renders the cover *inside* the calling
// view's tree, that tree is constrained to a tab's content area — so the
// system tab bar sits visually on top of the cover. Lifting the overlay to
// the root makes the cover sit on top of the tab bar, with the tab bar
// remaining mounted underneath (it doesn't animate in or out).
//
// Like before, this is BUTTON-DRIVEN: no edge-swipe. Open and close both
// happen only when code flips the binding. Presented views must use their
// own callback (e.g. `onClose: { showX = false }`) to dismiss —
// `@Environment(\.dismiss)` does NOT work here (no system presenter).

enum SlideCover {
    /// Snappy but smooth — close to a native push, intentionally quick.
    static let animation: Animation = .timingCurve(0.32, 0.72, 0, 1, duration: 0.34)
    /// Matches `animation.duration` — used to schedule unmount after slide-out.
    static let animationSeconds: Double = 0.34
}

// MARK: - Presenter

/// Holds the stack of slide covers currently presented. One per app root,
/// supplied via `SlideCoverHost`.
@MainActor
final class SlidePresenter: ObservableObject {
    struct Entry: Identifiable {
        let id: UUID
        let content: AnyView
        var visible: Bool
    }

    @Published private(set) var entries: [Entry] = []

    func push(id: UUID, content: AnyView) {
        // Guard against re-pushing the same modifier id (avoids duplicates).
        guard !entries.contains(where: { $0.id == id }) else { return }
        entries.append(Entry(id: id, content: content, visible: false))
        // Animate in on the next runloop tick so SwiftUI mounts at off-screen
        // first and then transitions to on-screen.
        DispatchQueue.main.async {
            withAnimation(SlideCover.animation) {
                if let idx = self.entries.firstIndex(where: { $0.id == id }) {
                    self.entries[idx].visible = true
                }
            }
        }
    }

    func dismiss(id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(SlideCover.animation) {
            entries[idx].visible = false
        }
        // Unmount once the slide-out has finished.
        DispatchQueue.main.asyncAfter(deadline: .now() + SlideCover.animationSeconds + 0.04) {
            self.entries.removeAll { $0.id == id }
        }
    }
}

// MARK: - Public API (modifier)

extension View {
    /// Presents `content` with a horizontal slide-in/out, gated on a Bool.
    /// The cover is rendered by the nearest `SlideCoverHost` ancestor so it
    /// can sit on top of any tab bar or root chrome.
    func slideCover<Cover: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Cover
    ) -> some View {
        modifier(SlideCoverModifier(isPresented: isPresented, content: content))
    }
}

private struct SlideCoverModifier<C: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder let content: () -> C
    @EnvironmentObject private var presenter: SlidePresenter
    /// Stable across re-renders of this modifier, so push/dismiss target the
    /// same entry on the presenter.
    @State private var entryID = UUID()

    func body(content base: Content) -> some View {
        base
            // React to the binding flipping; sync with the presenter.
            .onChange(of: isPresented) { _, new in
                if new {
                    presenter.push(id: entryID, content: AnyView(self.content()))
                } else {
                    presenter.dismiss(id: entryID)
                }
            }
            // If the presenting view leaves the tree while a cover is up
            // (e.g. tab swap), clear the cover too — otherwise it'd be
            // orphaned on the root overlay.
            .onDisappear {
                if isPresented {
                    presenter.dismiss(id: entryID)
                }
            }
    }
}

// MARK: - Host (rendered once at the app root)

/// Wraps the app's root content and provides the overlay layer used by
/// `.slideCover(...)`. Must be the ancestor of every view that calls
/// `.slideCover`, and must inject `SlidePresenter` into its content.
struct SlideCoverHost<Content: View>: View {
    @StateObject private var presenter = SlidePresenter()
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
                .environmentObject(presenter)

            GeometryReader { geo in
                ForEach(Array(presenter.entries.enumerated()), id: \.element.id) { idx, entry in
                    entry.content
                        // Inject the presenter again so nested `.slideCover`s
                        // inside an entry can push to this same overlay
                        // (e.g. Profile → Edit Profile).
                        .environmentObject(presenter)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .background(Color.bgPrimary.ignoresSafeArea())
                        .offset(x: entry.visible ? 0 : geo.size.width)
                        .zIndex(Double(100 + idx))
                        // Don't intercept touches while the cover is mounted
                        // but off-screen (sliding out / not yet slid in).
                        .allowsHitTesting(entry.visible)
                }
            }
            .ignoresSafeArea()
        }
    }
}
