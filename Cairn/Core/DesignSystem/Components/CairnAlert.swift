import SwiftUI

/// Native-iOS-feeling alert. White card centered on a dim overlay, with
/// Cancel + Confirm side-by-side at the bottom, separated by hairline dividers.
///
/// Visual model from mockup A ("Delete habit alert"):
///  - Serif bold title
///  - 2-line description body in textSecondary
///  - Horizontal action row, Cancel left / destructive right
///  - No icon — kept the parameter for API compatibility, but it's ignored
struct CairnAlertConfig {
    var title: String
    var message: String
    /// Retained for backwards compatibility with existing call sites.
    /// The redesigned alert doesn't render an icon — pass nil or just ignore.
    var icon: String? = nil
    var iconColor: Color = .accentCoral
    var confirmTitle: String = "Confirm"
    var confirmRole: ButtonRole? = nil
    var cancelTitle: String = "Cancel"
    var onConfirm: () -> Void
}

struct CairnAlert: ViewModifier {
    @Binding var isPresented: Bool
    let config: CairnAlertConfig

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation { isPresented = false }
                        }

                    card
                        .padding(.horizontal, 48)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: isPresented)
            }
        }
    }

    // MARK: Card

    private var card: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text(config.title)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(config.message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 18)

            Divider()
                .overlay(Color.textPrimary.opacity(0.12))

            // Action row — equal split with a vertical divider in the middle.
            HStack(spacing: 0) {
                actionButton(
                    title: config.cancelTitle,
                    color: Color.textPrimary,
                    weight: .regular
                ) {
                    withAnimation { isPresented = false }
                }

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.12))
                    .frame(width: 0.5)

                actionButton(
                    title: config.confirmTitle,
                    color: config.confirmRole == .destructive
                        ? Color.accentCoral
                        : Color.accentSage,
                    weight: .semibold
                ) {
                    withAnimation { isPresented = false }
                    config.onConfirm()
                }
            }
            .frame(height: 48)
        }
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.bgPrimary)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 10)
    }

    private func actionButton(
        title: String,
        color: Color,
        weight: Font.Weight,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: weight))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func cairnAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        icon: String? = nil,
        iconColor: Color = .accentCoral,
        confirmTitle: String = "Confirm",
        confirmRole: ButtonRole? = nil,
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(CairnAlert(
            isPresented: isPresented,
            config: CairnAlertConfig(
                title: title,
                message: message,
                icon: icon,
                iconColor: iconColor,
                confirmTitle: confirmTitle,
                confirmRole: confirmRole,
                cancelTitle: cancelTitle,
                onConfirm: onConfirm
            )
        ))
    }
}
