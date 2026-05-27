import SwiftUI

struct CairnAlertConfig {
    var title: String
    var message: String
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
                    // Run the action BEFORE dismissing. Callers often back their
                    // `isPresented` with a derived binding that clears pending
                    // state on dismiss; firing onConfirm first ensures that state
                    // is still readable when the action runs.
                    config.onConfirm()
                    withAnimation { isPresented = false }
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
