import SwiftUI

/// 首次启动引导：解释「一个 App = 很多个独立攒钱计划」
struct OnboardingView: View {

    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let message: String
        let tint: Color
        let bullets: [String]
    }

    private let pages: [Page] = [
        Page(
            symbol: "target",
            title: "一个 App，装下所有攒钱计划",
            message: "旅行、换电脑、给爸妈的红包——各攒各的，互不干扰。",
            tint: Theme.brand,
            bullets: ["每个计划有独立目标与进度", "总览页一眼看清一共攒了多少"]
        ),
        Page(
            symbol: "square.grid.3x3.fill",
            title: "有节奏地攒，更容易坚持",
            message: "挑战模式会帮你把每一格都排好日期，点一下就是一格。",
            tint: Theme.amber,
            bullets: ["52 周 / 365 天 / 阶梯递增", "逾期格子会标红提醒"]
        ),
        Page(
            symbol: "flame.fill",
            title: "连续打卡，看得见的成就感",
            message: "进度每跨过 25% 都会放彩带，连续天数会一直记着。",
            tint: Theme.danger,
            bullets: ["里程碑彩带与触觉反馈", "近 30 天存入柱状图"]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: Theme.Spacing.s) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? pages[page].tint : Color.secondary.opacity(0.25))
                        .frame(width: index == page ? 22 : 8, height: 8)
                        .animation(.snappy, value: page)
                }
            }
            .padding(.bottom, Theme.Spacing.l)

            VStack(spacing: Theme.Spacing.s) {
                Button {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        finish(openEditor: true)
                    }
                } label: {
                    Text(page < pages.count - 1 ? "继续" : "创建第一个计划")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.brand)

                Button("先随便看看") { finish(openEditor: false) }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .presentationDragIndicator(.visible)
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer(minLength: 0)

            Image(systemName: item.symbol)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(item.tint)
                .frame(width: 120, height: 120)
                .background(item.tint.opacity(0.12), in: Circle())

            VStack(spacing: Theme.Spacing.s) {
                Text(item.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(item.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.l)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                ForEach(item.bullets, id: \.self) { bullet in
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(item.tint)
                        Text(bullet).font(.subheadline)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(Theme.Spacing.m)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .padding(.horizontal, Theme.Spacing.l)

            Spacer(minLength: 0)
        }
    }

    private func finish(openEditor: Bool) {
        app.hasSeenOnboarding = true
        dismiss()
        if openEditor {
            // 等 sheet 关闭动画结束后再弹出新建面板，避免叠加
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                app.isPresentingPlanEditor = true
            }
        }
    }
}
