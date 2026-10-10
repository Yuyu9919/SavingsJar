import Foundation
import SwiftData

/// 一个独立的攒钱计划（一个 App 可以同时跑很多个）
@Model
final class SavingsPlan {

    // MARK: - 身份与外观
    /// 稳定标识（用于通知 ID 等场景；Identifiable 由 SwiftData 提供）
    var uuid: String = UUID().uuidString
    var name: String = ""
    var emoji: String = "💰"
    var colorHex: String = "#12B886"

    // MARK: - 目标
    var targetAmount: Double = 0
    var startDate: Date = Date()
    var deadline: Date?

    // MARK: - 节奏
    var modeRaw: String = SavingsMode.free.rawValue
    var periodUnitRaw: String = PeriodUnit.month.rawValue
    /// 定额金额 / 挑战基数
    var baseAmount: Double = 0
    /// 阶梯递增的期数（其它模式忽略）
    var periodCount: Int = 12

    // MARK: - 其它
    var note: String = ""
    var isArchived: Bool = false
    var createdAt: Date = Date()
    /// 每日提醒小时（-1 表示关闭）
    var reminderHour: Int = -1

    @Relationship(deleteRule: .cascade, inverse: \DepositRecord.plan)
    var deposits: [DepositRecord] = []

    init(
        name: String,
        emoji: String = "💰",
        colorHex: String = "#12B886",
        targetAmount: Double,
        startDate: Date = Date(),
        deadline: Date? = nil,
        mode: SavingsMode = .free,
        periodUnit: PeriodUnit = .month,
        baseAmount: Double = 0,
        periodCount: Int = 12,
        note: String = ""
    ) {
        self.uuid = UUID().uuidString
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.targetAmount = targetAmount
        self.startDate = startDate
        self.deadline = deadline
        self.modeRaw = mode.rawValue
        self.periodUnitRaw = periodUnit.rawValue
        self.baseAmount = baseAmount
        self.periodCount = periodCount
        self.note = note
        self.createdAt = Date()
    }

    // MARK: - 派生值

    var mode: SavingsMode {
        get { SavingsMode(rawValue: modeRaw) ?? .free }
        set { modeRaw = newValue.rawValue }
    }

    var periodUnit: PeriodUnit {
        get { PeriodUnit(rawValue: periodUnitRaw) ?? .month }
        set { periodUnitRaw = newValue.rawValue }
    }

    /// 已攒金额
    var savedAmount: Double {
        deposits.reduce(0) { $0 + $1.amount }
    }

    /// 完成度 0...1（可能 > 1，超出不裁剪，由 UI 决定）
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return savedAmount / targetAmount
    }

    var remainingAmount: Double {
        max(targetAmount - savedAmount, 0)
    }

    var isCompleted: Bool {
        targetAmount > 0 && savedAmount >= targetAmount
    }

    /// 剩余天数（无截止日期返回 nil）
    var daysLeft: Int? {
        guard let deadline else { return nil }
        let cal = Calendar.current
        let from = cal.startOfDay(for: Date())
        let to = cal.startOfDay(for: deadline)
        return cal.dateComponents([.day], from: from, to: to).day
    }

    /// 是否已逾期
    var isOverdue: Bool {
        guard let daysLeft else { return false }
        return daysLeft < 0 && !isCompleted
    }

    /// 距离截止日期，平均每天还需要存多少
    var suggestedDailyAmount: Double? {
        guard let daysLeft, daysLeft > 0 else { return nil }
        return remainingAmount / Double(daysLeft)
    }

    /// 全部计划序列（自由存返回空数组）
    var steps: [PlanEngine.Step] {
        PlanEngine.steps(for: self)
    }

    /// 打卡型计划：已完成的格子数
    var checkedStepCount: Int {
        deposits.compactMap(\.stepIndex).count
    }

    /// 最近一次存入日期
    var lastDepositDate: Date? {
        deposits.map(\.date).max()
    }
}
