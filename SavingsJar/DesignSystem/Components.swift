import SwiftUI

// MARK: - 进度环

struct ProgressRing<Label: View>: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 14
    var size: CGFloat = 168
    @ViewBuilder var label: () -> Label

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.7), tint],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: clamped)

            label()
                .padding(lineWidth)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("攒钱进度")
        .accessibilityValue("已完成百分之\(Int(clamped * 100))")
    }
}

extension ProgressRing where Label == EmptyView {
    init(progress: Double, tint: Color, lineWidth: CGFloat = 14, size: CGFloat = 168) {
        self.init(progress: progress, tint: tint, lineWidth: lineWidth, size: size) { EmptyView() }
    }
}

// MARK: - 数据小方块

struct StatTile: View {
    var title: String
    var value: String
    var symbol: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: Theme.Spacing.m)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(value)")
    }
}

// MARK: - 计划卡片

struct PlanCard: View {
    let plan: SavingsPlan
    var showsChevron: Bool = false

    private var color: Color { Color(hex: plan.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {

            HStack(spacing: Theme.Spacing.s) {
                Text(plan.emoji)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(plan.mode.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Theme.Spacing.s)

                if plan.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(color)
                } else {
                    Text("\(Int(plan.progress * 100))%")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(color)
                }

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            ProgressView(value: min(plan.progress, 1))
                .tint(color)

            HStack(spacing: Theme.Spacing.xs) {
                Text(Money.text(plan.savedAmount))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text("/ \(Money.compact(plan.targetAmount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if plan.isOverdue {
                    Label("已逾期", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.danger)
                } else if let daysLeft = plan.daysLeft, !plan.isCompleted {
                    Text(daysLeft == 0 ? "今天截止" : "还剩 \(daysLeft) 天")
                        .font(.caption)
                        .foregroundStyle(daysLeft <= 7 ? Theme.danger : .secondary)
                } else if plan.isCompleted {
                    Text("已达成")
                        .font(.caption)
                        .foregroundStyle(color)
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.name)，\(plan.mode.title)，已攒\(Money.text(plan.savedAmount))，目标\(Money.text(plan.targetAmount))，完成\(Int(min(plan.progress, 1) * 100)) %")
    }
}

// MARK: - 数字键盘

struct AmountKeypad: View {
    @Binding var text: String

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handle(key)
                        } label: {
                            Text(key)
                                .font(.system(size: 26, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(
                                    Color(.tertiarySystemFill),
                                    in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .accessibilityLabel(key == "⌫" ? "删除" : (key == "." ? "小数点" : key))
                    }
                }
            }
        }
    }

    private func handle(_ key: String) {
        Haptics.tap()
        switch key {
        case "⌫":
            if !text.isEmpty { text.removeLast() }
        case ".":
            if !text.contains(".") { text = text.isEmpty ? "0." : text + "." }
        default:
            // 最多两位小数
            if let dot = text.firstIndex(of: ".") {
                let decimals = text.distance(from: text.index(after: dot), to: text.endIndex)
                if decimals >= 2 { return }
            }
            if text == "0" { text = key } else { text += key }
            if text.count > 9 { text = String(text.prefix(9)) }
        }
    }
}

// MARK: - 彩带庆祝

struct ConfettiView: View {
    var isActive: Bool
    var particleCount: Int = 80

    private struct Particle {
        let x: Double, delay: Double, fall: Double, size: Double, spin: Double, sway: Double
        let colorIndex: Int
    }

    private var particles: [Particle] {
        (0..<particleCount).map { i in
            let seed = Double(i) * 0.6180339887
            return Particle(
                x: frac(seed * 7.13),
                delay: frac(seed * 3.71) * 0.5,
                fall: 0.28 + frac(seed * 5.19) * 0.32,
                size: 5 + frac(seed * 2.37) * 8,
                spin: frac(seed * 11.3) * 6,
                sway: frac(seed * 17.7) * 0.12,
                colorIndex: i % Theme.palette.count
            )
        }
    }

    private func frac(_ v: Double) -> Double { v - v.rounded(.down) }

    var body: some View {
        Group {
            if isActive {
                canvas
            } else {
                Color.clear
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var canvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let local = (t - p.delay).truncatingRemainder(dividingBy: 2.4)
                    guard local > 0 else { continue }
                    let progress = local / 2.4
                    let y = size.height * (progress / p.fall)
                    guard y < size.height + 20 else { continue }

                    let x = size.width * p.x + sin(progress * .pi * 3) * size.width * p.sway
                    let rect = CGRect(x: x, y: y, width: p.size, height: p.size * 0.62)

                    var ctx = context
                    ctx.translateBy(x: rect.midX, y: rect.midY)
                    ctx.rotate(by: .radians(progress * p.spin * .pi))
                    ctx.opacity = max(0, 1 - progress * 0.9)
                    ctx.fill(
                        Path(roundedRect: CGRect(x: -p.size / 2, y: -p.size * 0.31, width: p.size, height: p.size * 0.62), cornerRadius: 1.5),
                        with: .color(Theme.palette[p.colorIndex])
                    )
                }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - 空状态

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.brand)
                .frame(width: 84, height: 84)
                .background(Theme.brand.opacity(0.12), in: Circle())

            VStack(spacing: Theme.Spacing.xs) {
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.brand)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}

// MARK: - 段落标题

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 迷你柱状图

struct MiniBarChart: View {
    var data: [DailyTotal]
    var tint: Color

    private var maxValue: Double { max(data.map(\.total).max() ?? 1, 1) }
    private var barSpacing: CGFloat { data.count > 14 ? 2 : Theme.Spacing.xs }
    private var showsLabels: Bool { data.count <= 14 }

    var body: some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(data) { item in
                VStack(spacing: Theme.Spacing.xs) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            item.total > 0
                            ? LinearGradient(colors: [tint.opacity(0.72), tint], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [Color(.tertiarySystemFill), Color(.tertiarySystemFill)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(height: max(6, 78 * (item.total / maxValue)))
                    if showsLabels {
                        Text(weekdaySymbol(item.date))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("近七日存入")
        .accessibilityValue(data.map { "\(weekdaySymbol($0.date))\(Money.text($0.total))" }.joined(separator: "，"))
    }

    private func weekdaySymbol(_ date: Date) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        let index = Calendar.current.component(.weekday, from: date) - 1
        return names[max(0, min(names.count - 1, index))]
    }
}
