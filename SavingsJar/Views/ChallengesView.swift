import SwiftUI
import SwiftData

/// 挑战模板：一键把「有节奏的攒钱法」变成一个新计划
struct ChallengesView: View {

    struct Template: Identifiable {
        let id = UUID()
        let title: String
        let tagline: String
        let emoji: String
        let colorHex: String
        let mode: SavingsMode
        let base: Double
        let periodUnit: PeriodUnit
        let periodCount: Int
        let target: Double
        let days: Int

        var total: Double { target }
    }

    static let templates: [Template] = [
        Template(
            title: "52 周存钱挑战", tagline: "每周比上周多存 10 元，一年 13780 元",
            emoji: "🏆", colorHex: "#FF9F1C", mode: .week52,
            base: 10, periodUnit: .week, periodCount: 52,
            target: PlanEngine.plannedTotal(mode: .week52, base: 10, periodUnit: .week, periodCount: 52),
            days: 364
        ),
        Template(
            title: "365 天存钱挑战", tagline: "每天多存 1 元，一年 66795 元",
            emoji: "🌱", colorHex: "#12B886", mode: .day365,
            base: 1, periodUnit: .day, periodCount: 365,
            target: PlanEngine.plannedTotal(mode: .day365, base: 1, periodUnit: .day, periodCount: 365),
            days: 365
        ),
        Template(
            title: "12 月阶梯存", tagline: "每月递增 100 元，一年 7800 元",
            emoji: "📈", colorHex: "#7C6BFF", mode: .ladder,
            base: 100, periodUnit: .month, periodCount: 12,
            target: PlanEngine.plannedTotal(mode: .ladder, base: 100, periodUnit: .month, periodCount: 12),
            days: 365
        ),
        Template(
            title: "每天 10 元", tagline: "一杯奶茶钱，一年攒 3650 元",
            emoji: "☕️", colorHex: "#00BBF9", mode: .fixed,
            base: 10, periodUnit: .day, periodCount: 365, target: 3650, days: 365
        ),
        Template(
            title: "每月 500 元", tagline: "发薪日自动存，一年 6000 元",
            emoji: "💼", colorHex: "#3A86FF", mode: .fixed,
            base: 500, periodUnit: .month, periodCount: 12, target: 6000, days: 365
        )
    ]

    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<SavingsPlan> { !$0.isArchived },
           sort: [SortDescriptor(\SavingsPlan.createdAt, order: .reverse)])
    private var plans: [SavingsPlan]

    @State private var createdName: String?

    private var runningChallenges: [SavingsPlan] {
        plans.filter { $0.mode.isChallenge }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {

                header

                if !runningChallenges.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        SectionHeader(title: "进行中的挑战", subtitle: "共 \(runningChallenges.count) 个")

                        ForEach(runningChallenges) { plan in
                            NavigationLink {
                                PlanDetailView(plan: plan)
                            } label: {
                                ChallengeProgressRow(plan: plan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    SectionHeader(title: "挑战模板", subtitle: "挑一个难度合适的，一键开始")

                    ForEach(Self.templates) { template in
                        templateCard(template)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("存钱挑战")
        .overlay(alignment: .bottom) {
            if let createdName {
                Text("已创建「\(createdName)」")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("有节奏地攒，比硬攒更容易坚持")
                .font(.headline)
            Text("选一个挑战，App 会帮你把每一格都排好日期，每天点一格就行。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: Theme.Spacing.l)
    }

    private func templateCard(_ template: Template) -> some View {
        let color = Color(hex: template.colorHex)

        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Text(template.emoji)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title).font(.headline)
                    Text(template.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: Theme.Spacing.m) {
                metric("总目标", Money.compact(template.total))
                metric("每期基数", Money.text(template.base))
                metric("周期", template.mode == .day365 ? "365 天" : (template.mode == .week52 ? "52 周" : "\(template.periodCount) 期"))
            }

            Button {
                create(template)
            } label: {
                Text("开始这个挑战")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minTouch)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
        }
        .card()
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func create(_ template: Template) {
        Haptics.success()

        let deadline = Calendar.current.date(byAdding: .day, value: template.days, to: Date())
        let plan = SavingsPlan(
            name: template.title,
            emoji: template.emoji,
            colorHex: template.colorHex,
            targetAmount: template.total,
            startDate: Date(),
            deadline: deadline,
            mode: template.mode,
            periodUnit: template.periodUnit,
            baseAmount: template.base,
            periodCount: template.periodCount,
            note: "由「挑战模板」创建"
        )
        context.insert(plan)
        try? context.save()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { createdName = template.title }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { createdName = nil }
        }
    }
}

// MARK: - 进行中的挑战行

private struct ChallengeProgressRow: View {
    let plan: SavingsPlan

    private var color: Color { Color(hex: plan.colorHex) }

    var body: some View {
        let done = plan.deposits.compactMap(\.stepIndex).count
        let total = plan.steps.count

        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                Text(plan.emoji)
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name).font(.subheadline.weight(.semibold))
                    Text("已点亮 \(done) / \(total) 格")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            ProgressView(value: total > 0 ? Double(done) / Double(total) : 0)
                .tint(color)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.name)，已点亮 \(done) 格，共 \(total) 格")
    }
}
