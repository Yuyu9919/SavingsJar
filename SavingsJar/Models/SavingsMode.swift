import Foundation

/// 攒钱节奏：决定「每一期该存多少」的序列生成方式
enum SavingsMode: String, Codable, CaseIterable, Identifiable {
    case free      // 自由存：只设目标，不设节奏
    case fixed     // 定额存：每期固定金额（日 / 周 / 月）
    case week52    // 52 周挑战：第 n 周存 n × 基数
    case day365    // 365 天挑战：第 n 天存 n × 基数
    case ladder    // 阶梯递增：第 n 期存 n × 基数

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free:   return "自由存"
        case .fixed:  return "定额存"
        case .week52: return "52 周挑战"
        case .day365: return "365 天挑战"
        case .ladder: return "阶梯递增"
        }
    }

    var subtitle: String {
        switch self {
        case .free:   return "想存就存，只盯总目标"
        case .fixed:  return "每个周期存固定金额"
        case .week52: return "第 1 周 10 元，第 52 周 520 元"
        case .day365: return "每天多存 1 元，一年攒 66795 元"
        case .ladder: return "每期递增，越存越有劲"
        }
    }

    var symbol: String {
        switch self {
        case .free:   return "hand.tap.fill"
        case .fixed:  return "calendar.badge.clock"
        case .week52: return "calendar"
        case .day365: return "sun.max.fill"
        case .ladder: return "chart.line.uptrend.xyaxis"
        }
    }

    /// 是否是「格子打卡」型节奏（详情页会显示打卡网格）
    var isChallenge: Bool {
        switch self {
        case .free, .fixed: return false
        case .week52, .day365, .ladder: return true
        }
    }

    /// 是否为「每期金额固定」的节奏
    var isFixedAmount: Bool { self == .fixed }
}

/// 周期单位
enum PeriodUnit: String, Codable, CaseIterable, Identifiable {
    case day, week, month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:   return "每天"
        case .week:  return "每周"
        case .month: return "每月"
        }
    }

    var unitTitle: String {
        switch self {
        case .day:   return "天"
        case .week:  return "周"
        case .month: return "个月"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        }
    }
}
