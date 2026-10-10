import SwiftUI
import SwiftData

// MARK: - 全局 UI 状态

enum AppTab: Hashable {
    case dashboard, plans, challenges, profile
}

@Observable
final class AppState {
    var selectedTab: AppTab = .dashboard

    /// 新建计划（nil 表示关闭）
    var isPresentingPlanEditor = false
    /// 从「总览」直接跳到某个计划详情
    var focusedPlanID: UUID?

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "settings.hasSeenOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "settings.hasSeenOnboarding") }
    }
}

// MARK: - 根视图

struct RootView: View {

    @Environment(AppState.self) private var app
    @Query private var plans: [SavingsPlan]

    @State private var showOnboarding = false

    var body: some View {
        @Bindable var app = app

        TabView(selection: $app.selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("总览", systemImage: "chart.pie.fill") }
            .tag(AppTab.dashboard)

            NavigationStack {
                PlansView()
            }
            .tabItem { Label("计划", systemImage: "target") }
            .tag(AppTab.plans)

            NavigationStack {
                ChallengesView()
            }
            .tabItem { Label("挑战", systemImage: "flame.fill") }
            .tag(AppTab.challenges)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("我的", systemImage: "person.crop.circle") }
            .tag(AppTab.profile)
        }
        .sheet(isPresented: $app.isPresentingPlanEditor) {
            PlanEditorView(plan: nil)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .task {
            // 首次启动才展示引导页（说明「一个 App 可以建多个攒钱计划」）
            if !app.hasSeenOnboarding && plans.isEmpty {
                showOnboarding = true
            }
        }
    }
}
