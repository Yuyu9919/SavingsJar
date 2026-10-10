import SwiftUI
import SwiftData

/// 总览：一屏看清「一共攒了多少 / 今天该存多少 / 各计划进展」
struct DashboardView: View {

    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<SavingsPlan> { !$0.isArchived },
           sort: [SortDescriptor(\SavingsPlan.createdAt, order: .reverse)])
    private var plans: [SavingsPlan]

    @Query(sort: [SortDescriptor(\DepositRecord.date, order: .reverse)])
    private var allDeposits: [DepositRecord]

    @State private var quickDepositPlan: SavingsPlan?

    // MARK: - 汇总

    private var activePlans: [SavingsPlan] { plans.filter { !$0.isCompleted } }

    private var totalSaved: Double { plans.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { plans.reduce(0) { $0 + $1.targetAmount } }
    private var overallProgress: Double { totalTarget > 0 ? totalSaved / totalTarget : 0 }
    private var completedCount: Int { plans.filter(\.isCompleted).count }
    private var streak: Int { StreakCalculator.currentStreak(deposits: allDeposits) }
    private var todaySuggestion: Double { PlanEngine.todaySuggestion(for: plans) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                heroCard

                if todaySuggestion > 0 {
                    todayCard
                }

                if plans.isEmpty {
                    EmptyStateView(
                        symbol: "target",
                        title: "还没有攒钱计划",
                        message: "可以同时开好几个计划：旅行基金、换电脑、给爸妈的红包，各攒各的。",
                        actionTitle: "创建第一个计划"
                    ) { app.isPresentingPlanEditor = true }
                    .card()
                } else {
                    weekChartCard
                    planSection
                }

                streakCard
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("我的攒钱罐")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    app.isPresentingPlanEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新建攒钱计划")
            }
        }
        .sheet(item: $quickDepositPlan) { plan in
            DepositSheet(plan: plan)
        }
    }

    // MARK: - 顶部总览

    private var heroCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            HStack(alignment: .center, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("累计已攒")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(Money.text(totalSaved))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    if totalTarget > 0 {
                        Text("目标 \(Money.compact(totalTarget))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                ProgressRing(progress: overallProgress, tint: Theme.brand, lineWidth: 11, size: 92) {
                    VStack(spacing: 0) {
                        Text("\(Int(min(overallProgress, 1) * 100))%")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .monospacedDigit()
                        Text("完成")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: Theme.Spacing.s) {
                StatTile(title: "进行中", value: "\(activePlans.count) 个", symbol: "target", tint: Theme.brand)
                StatTile(title: "已完成", value: "\(completedCount) 个", symbol: "checkmark.seal.fill", tint: Theme.amber)
            }
        }
        .padding(Theme.Spacing.l)
        .background(
            LinearGradient(
                colors: [Theme.brand.opacity(0.10), Color(.secondarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
        )
    }

    // MARK: - 今日待办

    private var todayCard: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 44, height: 44)
                .background(Theme.brand.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("今天该存")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Money.text(todaySuggestion))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
            }

            Spacer()

            Button {
                Haptics.tap()
                quickDepositPlan = firstPendingPlan
            } label: {
                Text("去打卡")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, Theme.Spacing.m)
                    .frame(minHeight: Theme.minTouch)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.brand)
            .disabled(firstPendingPlan == nil)
        }
        .card()
    }

    private var firstPendingPlan: SavingsPlan? {
        activePlans.first { PlanEngine.nextStep(for: $0) != nil } ?? activePlans.first
    }

    // MARK: - 近七日

    private var weekChartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "近 7 天存入", subtitle: weekSummary)
            MiniBarChart(data: StreakCalculator.dailyTotals(deposits: allDeposits, days: 7), tint: Theme.brand)
        }
        .card()
    }

    private var weekSummary: String {
        let week = StreakCalculator.dailyTotals(deposits: allDeposits, days: 7).reduce(0) { $0 + $1.total }
        return week > 0 ? "合计 \(Money.text(week))" : "本周还没有存入记录"
    }

    // MARK: - 计划列表

    private var planSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                SectionHeader(title: "攒钱计划", subtitle: "共 \(plans.count) 个")
                Button("全部") {
                    Haptics.tap()
                    app.selectedTab = .plans
                }
                .font(.subheadline)
                .foregroundStyle(Theme.brand)
            }

            ForEach(plans.prefix(4)) { plan in
                NavigationLink {
                    PlanDetailView(plan: plan)
                } label: {
                    PlanCard(plan: plan, showsChevron: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 连续打卡

    private var streakCard: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(streak > 0 ? Theme.amber : .secondary)
                .frame(width: 44, height: 44)
                .background((streak > 0 ? Theme.amber : Color.secondary).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(streak > 0 ? "连续打卡 \(streak) 天" : "今天还没有存入")
                    .font(.headline)
                Text(streak > 0 ? "最长记录 \(StreakCalculator.longestStreak(deposits: allDeposits)) 天，保持住" : "存一笔就能点亮今天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
