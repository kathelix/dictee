import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("revisitSessionCap") private var revisitSessionCap: Int = 20

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(
                        "Max words per Revisit: \(revisitSessionCap)",
                        value: $revisitSessionCap,
                        in: 5...50,
                        step: 5
                    )
                } header: {
                    Text("Revisit Session")
                } footer: {
                    Text("Caps how many Review Bank words appear in a single Revisit session. Oldest-added words are shown first.")
                }

                Section("About") {
                    LabeledContent("App", value: "Dictée")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
