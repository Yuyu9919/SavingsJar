import SwiftUI
import SwiftData

/// 我的：数据统计 + 设置
struct ProfileView: View {

    @Query(sort: [SortDescriptor(\SavingsPlan.createdAt, order: .reverse)])
    private var plans: [SavingsPlan]

    @Query(sort: [SortDescriptor(\DepositRecord.date, order: .reverse)])
    private var deposits: [DepositRecord]

    @AppStorage("settings.currencySymbol") private var currencySymbol = "¥"
    @AppStorage("settings.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("settings.dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("settings.reminderHour") private var reminderHour = 20

    private var totalSaved: Double { plans.reduce(0) { $0 + $1.savedAmount } }
    private var completedCount: Int { plans.filter(\.isCompleted).count }
    private var streak: Int { StreakCalculator.currentStreak(deposits: deposits) }
    private var longest: Int { StreakCalculator.longestStreak(deposits: deposits) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                summaryCard
                monthChartCard
                settingsCard
                aboutCard
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("我的")
        .task {
            // 回到本页时同步一次系统里的提醒时间
            if dailyReminderEnabled {
                await NotificationManager.shared.scheduleDaily(hour: reminderHour)
            }
        }
    }

    // MARK: - 汇总

    private var summaryCard: some View {
        VStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("累计攒下")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Money.text(totalSaved))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Theme.Spacing.s) {
                StatTile(title: "计划总数", value: "\(plans.count)", symbol: "target", tint: Theme.brand)
                StatTile(title: "已完成", value: "\(completedCount)", symbol: "checkmark.seal.fill", tint: Theme.amber)
                StatTile(title: "连续天数", value: "\(streak)", symbol: "flame.fill", tint: Theme.danger)
            }
        }
        .card(padding: Theme.Spacing.l)
    }

    private var monthChartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(
                title: "近 30 天存入",
                subtitle: "最长连续 \(longest) 天 · 共 \(deposits.count) 笔记录"
            )
            MiniBarChart(data: StreakCalculator.dailyTotals(deposits: deposits, days: 30), tint: Theme.brand)
        }
        .card()
    }

    // MARK: - 设置

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "设置")
                .padding(.bottom, Theme.Spacing.s)

            HStack {
                Label("货币符号", systemImage: "yensign.circle")
                Spacer()
                Picker("货币符号", selection: $currencySymbol) {
                    ForEach(["¥", "$", "€", "£", "HK$"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .frame(minHeight: Theme.minTouch)

            Divider()

            Toggle(isOn: $hapticsEnabled) {
                Label("触觉反馈", systemImage: "hand.tap")
            }
            .frame(minHeight: Theme.minTouch)

            Divider()

            Toggle(isOn: $dailyReminderEnabled) {
                Label("每日攒钱提醒", systemImage: "bell.badge")
            }
            .frame(minHeight: Theme.minTouch)
            .onChange(of: dailyReminderEnabled) { _, enabled in
                Task {
                    if enabled {
                        await NotificationManager.shared.scheduleDaily(hour: reminderHour)
                    } else {
                        NotificationManager.shared.cancelDaily()
                    }
                }
            }

            if dailyReminderEnabled {
                HStack {
                    Text("提醒时间")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("提醒时间", selection: $reminderHour) {
                        ForEach(6...23, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: reminderHour) { _, hour in
                        Task { await NotificationManager.shared.scheduleDaily(hour: hour) }
                    }
                }
                .frame(minHeight: Theme.minTouch)
            }
        }
        .card()
    }

    // MARK: - 关于 / 导出

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(title: "数据")

            ShareLink(item: csvText) {
                Label("导出全部记录（CSV）", systemImage: "square.and.arrow.up")
                    .frame(minHeight: Theme.minTouch)
            }
            .disabled(deposits.isEmpty)

            Divider()

            HStack {
                Label("版本", systemImage: "info.circle")
                Spacer()
                Text("1.0.0").foregroundStyle(.secondary)
            }
            .frame(minHeight: Theme.minTouch)

            Text("所有数据都保存在本机，不会上传。删除 App 会一并清除，请定期用 CSV 备份。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var csvText: String {
        var lines = ["计划,日期,金额,来源,期数,备注"]
        for record in deposits {
            let planName = record.plan?.name ?? "未知计划"
            let dateText = DateText.full(record.date)
            let source = record.source.title
            let step = record.stepIndex.map(String.init) ?? ""
            let note = record.note.replacingOccurrences(of: ",", with: "，")
            lines.append("\(planName),\(dateText),\(record.amount),\(source),\(step),\(note)")
        }
        return lines.joined(separator: "\n")
    }
}
