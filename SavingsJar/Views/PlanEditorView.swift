import SwiftUI
import SwiftData

/// 新建 / 编辑攒钱计划
struct PlanEditorView: View {

    /// nil = 新建
    let plan: SavingsPlan?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "💰"
    @State private var colorHex = Theme.paletteHex[0]
    @State private var targetText = ""
    @State private var startDate = Date()
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var mode: SavingsMode = .free
    @State private var baseText = ""
    @State private var periodUnit: PeriodUnit = .month
    @State private var periodCount = 12
    @State private var note = ""
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()

    @FocusState private var focusedField: Field?
    enum Field { case name, target, base, note }

    private var isEditing: Bool { plan != nil }
    private var color: Color { Color(hex: colorHex) }
    private var base: Double { Double(baseText) ?? 0 }

    /// 挑战模式自动算出的总额；自由 / 定额模式用用户输入
    private var effectiveTarget: Double {
        switch mode {
        case .free, .fixed:
            return Double(targetText) ?? 0
        case .week52, .day365, .ladder:
            return PlanEngine.plannedTotal(mode: mode, base: base, periodUnit: periodUnit, periodCount: periodCount)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && effectiveTarget > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                appearanceSection
                targetSection
                rhythmSection
                extraSection
            }
            .navigationTitle(isEditing ? "编辑计划" : "新建攒钱计划")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { focusedField = nil }
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - 预览

    private var previewSection: some View {
        Section {
            VStack(spacing: Theme.Spacing.s) {
                HStack(spacing: Theme.Spacing.s) {
                    Text(emoji)
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(color.opacity(0.15), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "未命名计划" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)
                        Text(mode.title).font(.caption).foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(Money.compact(effectiveTarget))
                        .font(.system(.headline, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(color)
                }

                if !summaryText.isEmpty {
                    HStack {
                        Text(summaryText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
    }

    private var summaryText: String {
        switch mode {
        case .free:
            return "想存多少就存多少，只盯总目标。"
        case .fixed:
            guard base > 0 else { return "" }
            let count = Int(ceil(effectiveTarget / base))
            return "\(periodUnit.title)存 \(Money.text(base))，约 \(count) \(periodUnit.unitTitle)完成"
        case .week52:
            return "第 1 周 \(Money.text(base))，第 52 周 \(Money.text(base * 52))，合计 \(Money.text(effectiveTarget))"
        case .day365:
            return "每天比前一天多存 \(Money.text(base))，一年合计 \(Money.text(effectiveTarget))"
        case .ladder:
            return "\(periodUnit.title)递增 \(Money.text(base))，共 \(periodCount) 期，合计 \(Money.text(effectiveTarget))"
        }
    }

    // MARK: - 外观

    private var appearanceSection: some View {
        Section("计划外观") {
            TextField("计划名称，如「北海道旅行基金」", text: $name)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("图标").font(.caption).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(Theme.emojiChoices, id: \.self) { item in
                            Button {
                                Haptics.soft()
                                emoji = item
                            } label: {
                                Text(item)
                                    .font(.system(size: 20))
                                    .frame(width: 40, height: 40)
                                    .background(emoji == item ? color.opacity(0.2) : Color(.tertiarySystemFill), in: Circle())
                                    .overlay {
                                        if emoji == item {
                                            Circle().stroke(color, lineWidth: 2)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("图标 \(item)")
                            .accessibilityAddTraits(emoji == item ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("颜色").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(Theme.paletteHex, id: \.self) { hex in
                        Button {
                            Haptics.soft()
                            colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("颜色 \(hex)")
                        .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - 目标

    private var targetSection: some View {
        Section("目标") {
            if mode == .free || mode == .fixed {
                HStack {
                    Text("目标金额")
                    Spacer()
                    TextField("0", text: $targetText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .target)
                        .frame(maxWidth: 140)
                    Text(Money.symbol).foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Text("目标金额")
                    Spacer()
                    Text(Money.text(effectiveTarget))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Text("（自动）").font(.caption).foregroundStyle(.tertiary)
                }
            }

            DatePicker("开始日期", selection: $startDate, displayedComponents: .date)

            Toggle("设置截止日期", isOn: $hasDeadline.animation())
            if hasDeadline {
                DatePicker("截止日期", selection: $deadline, in: startDate..., displayedComponents: .date)
            }
        }
    }

    // MARK: - 节奏

    private var rhythmSection: some View {
        Section("攒钱节奏") {
            ForEach(SavingsMode.allCases) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) {
                        mode = item
                        applyDefaults(for: item)
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(mode == item ? .white : color)
                            .frame(width: 30, height: 30)
                            .background(mode == item ? color : color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(item.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if mode == item {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(color)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == item ? .isSelected : [])
            }

            if mode != .free {
                HStack {
                    Text(mode == .fixed ? "每期金额" : "递增基数")
                    Spacer()
                    TextField("0", text: $baseText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .base)
                        .frame(maxWidth: 120)
                    Text(Money.symbol).foregroundStyle(.secondary)
                }
            }

            if mode == .fixed || mode == .ladder {
                Picker("周期", selection: $periodUnit) {
                    ForEach(PeriodUnit.allCases) { Text($0.title).tag($0) }
                }
            }

            if mode == .ladder {
                Stepper("期数：\(periodCount) 期", value: $periodCount, in: 2...120)
            }
        }
    }

    // MARK: - 其它

    private var extraSection: some View {
        Section("其它") {
            TextField("备注（可选）", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .focused($focusedField, equals: .note)

            Toggle("每日提醒", isOn: $reminderEnabled.animation())
            if reminderEnabled {
                DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    // MARK: - 逻辑

    private func applyDefaults(for mode: SavingsMode) {
        guard !isEditing else { return }
        switch mode {
        case .free:
            break
        case .fixed:
            if baseText.isEmpty { baseText = "500" }
            if targetText.isEmpty { targetText = "6000" }
        case .week52:
            if baseText.isEmpty { baseText = "10" }
        case .day365:
            if baseText.isEmpty { baseText = "1" }
        case .ladder:
            if baseText.isEmpty { baseText = "100" }
        }
    }

    private func load() {
        guard let plan else {
            applyDefaults(for: mode)
            return
        }
        name = plan.name
        emoji = plan.emoji
        colorHex = plan.colorHex
        targetText = plan.targetAmount > 0 ? String(format: "%.0f", plan.targetAmount) : ""
        startDate = plan.startDate
        if let d = plan.deadline {
            hasDeadline = true
            deadline = d
        }
        mode = plan.mode
        baseText = plan.baseAmount > 0 ? String(format: "%.0f", plan.baseAmount) : ""
        periodUnit = plan.periodUnit
        periodCount = plan.periodCount
        note = plan.note
        if plan.reminderHour >= 0 {
            reminderEnabled = true
            reminderTime = Calendar.current.date(bySettingHour: plan.reminderHour, minute: 0, second: 0, of: Date()) ?? reminderTime
        }
    }

    private func save() {
        Haptics.success()
        focusedField = nil

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let hour = reminderEnabled ? Calendar.current.component(.hour, from: reminderTime) : -1

        let saved: SavingsPlan
        if let plan {
            plan.name = trimmedName
            plan.emoji = emoji
            plan.colorHex = colorHex
            plan.targetAmount = effectiveTarget
            plan.startDate = startDate
            plan.deadline = hasDeadline ? deadline : nil
            plan.mode = mode
            plan.baseAmount = base
            plan.periodUnit = periodUnit
            plan.periodCount = periodCount
            plan.note = note.trimmingCharacters(in: .whitespaces)
            plan.reminderHour = hour
            saved = plan
        } else {
            let newPlan = SavingsPlan(
                name: trimmedName,
                emoji: emoji,
                colorHex: colorHex,
                targetAmount: effectiveTarget,
                startDate: startDate,
                deadline: hasDeadline ? deadline : nil,
                mode: mode,
                periodUnit: periodUnit,
                baseAmount: base,
                periodCount: periodCount,
                note: note.trimmingCharacters(in: .whitespaces)
            )
            newPlan.reminderHour = hour
            context.insert(newPlan)
            saved = newPlan
        }

        try? context.save()

        if let deadline = saved.deadline, !saved.isCompleted {
            Task {
                await NotificationManager.shared.scheduleDeadline(
                    id: saved.uuid, name: saved.name, deadline: deadline
                )
            }
        }

        dismiss()
    }
}
