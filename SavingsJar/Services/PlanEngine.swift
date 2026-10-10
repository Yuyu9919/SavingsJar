import Foundation

/// 计划序列引擎：把「模式 + 基数」翻译成一条可执行的存钱时间表
enum PlanEngine {

    /// 时间表里的一格
    struct Step: Identifiable, Hashable {
        let index: Int        // 1 起
        let amount: Double
        let dueDate: Date
        var id: Int { index }
    }

    // MARK: - 序列生成

    static func steps(for plan: SavingsPlan) -> [Step] {
        let cal = Calendar.current
        switch plan.mode {

        case .free:
            return []

        case .fixed:
            let per = max(plan.baseAmount, 0.01)
            let count = max(1, Int(ceil(plan.targetAmount / per)))
            return (1...count).map { i in
                Step(
                    index: i,
                    amount: per,
                    dueDate: cal.date(byAdding: plan.periodUnit.component, value: i - 1, to: plan.startDate) ?? plan.startDate
                )
            }

        case .week52:
            return (1...52).map { i in
                Step(
                    index: i,
                    amount: plan.baseAmount * Double(i),
                    dueDate: cal.date(byAdding: .weekOfYear, value: i - 1, to: plan.startDate) ?? plan.startDate
                )
            }

        case .day365:
            return (1...365).map { i in
                Step(
                    index: i,
                    amount: plan.baseAmount * Double(i),
                    dueDate: cal.date(byAdding: .day, value: i - 1, to: plan.startDate) ?? plan.startDate
                )
            }

        case .ladder:
            let n = max(plan.periodCount, 1)
            return (1...n).map { i in
                Step(
                    index: i,
                    amount: plan.baseAmount * Double(i),
                    dueDate: cal.date(byAdding: plan.periodUnit.component, value: i - 1, to: plan.startDate) ?? plan.startDate
                )
            }
        }
    }

    // MARK: - 预计算总额（新建计划时用来回填目标）

    static func plannedTotal(mode: SavingsMode, base: Double, periodUnit: PeriodUnit, periodCount: Int) -> Double {
        switch mode {
        case .free:
            return 0
        case .fixed:
            return base * Double(max(periodCount, 1))
        case .week52:
            return base * (1...52).reduce(0) { $0 + Double($1) }        // base × 1378
        case .day365:
            return base * (1...365).reduce(0) { $0 + Double($1) }       // base × 66795
        case .ladder:
            return base * Double((1...max(periodCount, 1)).reduce(0) { $0 + $1 })
        }
    }

    /// 下一个待打卡的格子（首页「今天该存多少」用）
    static func nextStep(for plan: SavingsPlan) -> Step? {
        let done = Set(plan.deposits.compactMap(\.stepIndex))
        return steps(for: plan).first { !done.contains($0.index) }
    }

    // MARK: - 建议

    /// 首页顶部「今日建议存入」：把所有进行中的计划拉平求和
    static func todaySuggestion(for plans: [SavingsPlan]) -> Double {
        plans.filter { !$0.isArchived && !$0.isCompleted }.reduce(0) { sum, plan in
            guard let step = nextStep(for: plan) else { return sum }
            let cal = Calendar.current
            if cal.isDateInToday(step.dueDate) || (step.dueDate < Date() && !plan.deposits.contains(where: { $0.stepIndex == step.index })) {
                // 只把「今天或已逾期」的格子算进今日待办
                return sum + step.amount
            }
            return sum
        }
    }

    /// 逾期格子数量
    static func overdueStepCount(for plan: SavingsPlan) -> Int {
        guard plan.mode.isChallenge else { return 0 }
        let done = Set(plan.deposits.compactMap(\.stepIndex))
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return steps(for: plan).filter { !done.contains($0.index) && cal.startOfDay(for: $0.dueDate) < today }.count
    }
}

// MARK: - 图表数据

/// 单日存入合计（柱状图数据源）
struct DailyTotal: Identifiable, Hashable {
    let id: Date
    let date: Date
    let total: Double
}

// MARK: - 连续打卡

enum StreakCalculator {

    /// 连续存入天数（今天或昨天有存入即算「活着」）
    static func currentStreak(deposits: [DepositRecord]) -> Int {
        let cal = Calendar.current
        let days = Set(deposits.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        let today = cal.startOfDay(for: Date())
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today), days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func longestStreak(deposits: [DepositRecord]) -> Int {
        let cal = Calendar.current
        let days = Set(deposits.map { cal.startOfDay(for: $0.date) }).sorted()
        guard !days.isEmpty else { return 0 }

        var best = 1, run = 1
        for i in 1..<days.count {
            let diff = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if diff == 1 {
                run += 1
                best = max(best, run)
            } else if diff > 1 {
                run = 1
            }
        }
        return best
    }

    /// 近 N 天的每日存入合计，用于柱状图
    static func dailyTotals(deposits: [DepositRecord], days: Int) -> [DailyTotal] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var bucket: [Date: Double] = [:]
        for d in deposits {
            let key = cal.startOfDay(for: d.date)
            bucket[key, default: 0] += d.amount
        }
        return (0..<days).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DailyTotal(id: day, date: day, total: bucket[day] ?? 0)
        }
    }
}
