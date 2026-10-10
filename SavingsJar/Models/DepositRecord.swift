import Foundation
import SwiftData

/// 一笔存入记录
@Model
final class DepositRecord {

    var uuid: String = UUID().uuidString
    var amount: Double = 0
    var date: Date = Date()
    var note: String = ""
    var sourceRaw: String = DepositSource.manual.rawValue
    /// 对应挑战序列的序号（1 起）。自由存入时为 nil
    var stepIndex: Int?
    /// 记录创建时间，用于同秒排序稳定
    var createdAt: Date = Date()

    var plan: SavingsPlan?

    init(
        amount: Double,
        date: Date = Date(),
        note: String = "",
        source: DepositSource = .manual,
        stepIndex: Int? = nil,
        plan: SavingsPlan? = nil
    ) {
        self.uuid = UUID().uuidString
        self.amount = amount
        self.date = date
        self.note = note
        self.sourceRaw = source.rawValue
        self.stepIndex = stepIndex
        self.createdAt = Date()
        self.plan = plan
    }

    var source: DepositSource {
        get { DepositSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}

enum DepositSource: String, Codable {
    case manual       // 手动存入
    case checkIn      // 挑战打卡
    case quickAdd     // 快捷金额

    var title: String {
        switch self {
        case .manual:   return "手动存入"
        case .checkIn:  return "挑战打卡"
        case .quickAdd: return "快捷存入"
        }
    }

    var symbol: String {
        switch self {
        case .manual:   return "plus.circle.fill"
        case .checkIn:  return "checkmark.circle.fill"
        case .quickAdd: return "bolt.fill"
        }
    }
}
