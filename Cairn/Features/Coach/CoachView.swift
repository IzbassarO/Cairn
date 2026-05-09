import SwiftUI

struct CoachView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Spacer().frame(height: 40)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentSage.opacity(0.55))
                        .padding(.bottom, Spacing.sm)

                    VStack(spacing: Spacing.sm) {
                        Text("Your coach is on the way.")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("A kind, neuroaffirming voice that learns your patterns and checks in when it matters. Arrives with the AI release.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    CairnCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "quote.opening")
                                    .foregroundStyle(Color.accentCoral)
                                Text("preview")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.textTertiary)
                                    .textCase(.uppercase)
                            }
                            Text("\"Morning. You logged meds 6 of the last 7 days — the rhythm's there. Today is wide open.\"")
                                .font(.system(size: 15, design: .rounded))
                                .italic()
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Coach")
        }
    }
}
