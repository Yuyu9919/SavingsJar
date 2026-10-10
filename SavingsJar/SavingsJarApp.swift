import SwiftUI
import SwiftData

@main
struct SavingsJarApp: App {

    @State private var app = AppState()
    private let container: ModelContainer

    init() {
        let schema = Schema([SavingsPlan.self, DepositRecord.self])
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            // 迁移失败时退回内存库，保证不因数据问题启动崩溃
            container = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
        NotificationManager.shared.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .tint(Theme.brand)
        }
        .modelContainer(container)
    }
}
