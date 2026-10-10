import SwiftUI

// MARK: - 颜色工具

extension Color {
    /// 支持 "#RRGGBB" / "RRGGBB" / "#AARRGGBB"
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 8 { s = String(s.dropFirst(2)) }   // 丢弃 alpha 通道
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - 设计令牌

/// 全 App 统一的颜色 / 间距 / 圆角，禁止在视图里散落魔法数字
enum Theme {

    /// 品牌主色（薄荷绿 —— 代表增长）
    static let brand = Color(hex: "#12B886")
    /// 强调色（暖琥珀 —— 代表金币）
    static let amber = Color(hex: "#FFB703")
    /// 危险 / 逾期
    static let danger = Color(hex: "#EF476F")

    /// 计划可选色板
    static let paletteHex: [String] = [
        "#12B886", "#3A86FF", "#7C6BFF", "#F15BB5",
        "#FF9F1C", "#EF476F", "#00BBF9", "#8AC926"
    ]
    static var palette: [Color] { paletteHex.map { Color(hex: $0) } }

    /// 可选图标（emoji）
    static let emojiChoices: [String] = [
        "💰", "🏖️", "💻", "🚗", "🏠", "🎓", "🎁", "📷",
        "🎮", "🐱", "✈️", "⌚️", "🛋️", "☕️", "💍", "🏔️",
        "🎸", "📚", "🍜", "💪"
    ]

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let chip: CGFloat = 10
        static let field: CGFloat = 14
        static let card: CGFloat = 20
        static let sheet: CGFloat = 28
    }

    /// Apple HIG 最小触控目标
    static let minTouch: CGFloat = 44
}

// MARK: - 卡片

private struct CardModifier: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            )
    }
}

extension View {
    /// 统一卡片容器
    func card(padding: CGFloat = Theme.Spacing.m) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - 金额格式化

enum Money {

    static var symbol: String {
        UserDefaults.standard.string(forKey: "settings.currencySymbol") ?? "¥"
    }

    /// 12345.6 → "¥12,346"
    static func text(_ value: Double, decimals: Bool = false) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.minimumFractionDigits = decimals ? 2 : 0
        f.maximumFractionDigits = decimals ? 2 : 0
        let n = f.string(from: NSNumber(value: value)) ?? "0"
        return symbol + n
    }

    /// 空间不够时用：12345 → "¥1.23万"
    static func compact(_ value: Double) -> String {
        if value >= 100_000_000 { return symbol + String(format: "%.2f亿", value / 100_000_000) }
        if value >= 10_000 { return symbol + String(format: "%.2f万", value / 10_000) }
        return text(value)
    }
}

// MARK: - 日期格式化

enum DateText {
    private static let md: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f
    }()

    private static let ymd: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    static func short(_ date: Date) -> String { md.string(from: date) }
    static func full(_ date: Date) -> String { ymd.string(from: date) }

    /// 「今天 / 昨天 / 3天前 / 5月2日」
    static func relative(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInYesterday(date) { return "昨天" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        if days > 1 && days < 7 { return "\(days) 天前" }
        return short(date)
    }
}
