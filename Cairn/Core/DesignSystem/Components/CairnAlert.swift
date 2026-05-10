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
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation { isPresented = false }
                        }

                    VStack(spacing: Spacing.md) {
                        if let icon = config.icon {
                            Image(systemName: icon)
                                .font(.system(size: 32, weight: .regular))
                                .foregroundStyle(config.iconColor)
                                .frame(width: 64, height: 64)
                                .background(
                                    Circle().fill(config.iconColor.opacity(0.15))
                                )
                                .padding(.bottom, Spacing.xs)
                        }

                        Text(config.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(config.message)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.sm)

                        VStack(spacing: Spacing.sm) {
                            Button {
                                withAnimation { isPresented = false }
                                config.onConfirm()
                            } label: {
                                Text(config.confirmTitle)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        Capsule().fill(
                                            config.confirmRole == .destructive
                                                ? Color.accentCoral
                                                : Color.accentSage
                                        )
                                    )
                            }

                            Button {
                                withAnimation { isPresented = false }
                            } label: {
                                Text(config.cancelTitle)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.textSecondary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            }
                        }
                        .padding(.top, Spacing.sm)
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: 340)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.bgPrimary)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 10)
                    .padding(.horizontal, Spacing.xl)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
            }
        }
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
