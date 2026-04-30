import SwiftUI
import SwiftData

@main
struct DicteeApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [
            WordList.self,
            Word.self,
            ReviewBankEntry.self,
            SessionResult.self,
            Answer.self,
            RewardTransaction.self,
        ])
    }
}
