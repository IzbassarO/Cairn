import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "applelogo")
                            .foregroundStyle(Color.textPrimary)
                        Text("Sign in with Apple")
                            .foregroundStyle(Color.textTertiary)
                        Spacer()
                        Text("week 3")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.bgTertiary))
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    rowPlaceholder("Notifications", "bell.fill", note: "week 2")
                    rowPlaceholder("Coach tone", "leaf.fill", note: "week 5")
                    rowPlaceholder("iCloud sync", "icloud.fill", note: "auto")
                    rowPlaceholder("Appearance", "paintpalette.fill", note: "week 3")
                } header: {
                    Text("Preferences")
                }

                Section {
                    rowPlaceholder("Export data", "square.and.arrow.up", note: "v1.4")
                    rowPlaceholder("Delete all data", "trash", note: "week 3", destructive: true)
                } header: {
                    Text("Data")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(Color.textTertiary)
                    }
                } header: {
                    Text("About")
                }

                Section {
                    Text("Made for ADHD brains, not against them.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.sm)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func rowPlaceholder(_ title: String, _ icon: String, note: String, destructive: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(destructive ? Color.accentCoral : Color.textPrimary)
            Text(title)
                .foregroundStyle(destructive ? Color.accentCoral : Color.textTertiary)
            Spacer()
            Text(note)
                .font(.system(size: 11))
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.bgTertiary))
        }
    }
}

private extension Bundle {
    var appVersion: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
