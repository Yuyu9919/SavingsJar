import SwiftUI
import SwiftData

/// 计划详情：进度环 + 打卡网格 + 存入记录
struct PlanDetailView: View {

    let plan: SavingsPlan

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var segment: Segment = .progress
    @State private var showDepositSheet = false
    @State private var depositPrefill: Double?
    @State private var depositStepIndex: Int?
    @State private var showEditSheet = false
    @State private var celebrate = false
    @State private var toast: String?
    @State private var confirmDelete = false

    enum Segment: String, CaseIterable, Identifiable {
        case progress = "进度", records = "记录"
        var id: String { rawValue }
    }

    private var color: Color { Color(hex: plan.colorHex) }
    private var sortedDeposits: [DepositRecord] {
        plan.deposits.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.m) {
                    hero
                    statRow
                    modeCard

                    if plan.mode.isChallenge {
                        checkInCard
                    }

                    Picker("视图", selection: $segment) {
                        ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch segment {
                    case .progress: progressSection
                    case .records:  recordsSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.bottom, 120)
            }
            .background(Color(.systemGroupedBackground))

            ConfettiView(isActive: celebrate)

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.s)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 110)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .allowsHitTesting(false)
            }
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Haptics.tap()
                        showEditSheet = true
                    } label: {
                        Label("编辑计划", systemImage: "pencil")
                    }
                    Button {
                        Haptics.tap()
                        plan.isArchived.toggle()
                        try? context.save()
                        if plan.isArchived { dismiss() }
                    } label: {
                        Label(plan.isArchived ? "取消归档" : "归档计划", systemImage: "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("删除计划", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("更多操作")
            }
        }
        .sheet(isPresented: $showDepositSheet) {
            DepositSheet(plan: plan, prefilledAmount: depositPrefill, stepIndex: depositStepIndex)
        }
        .sheet(isPresented: $showEditSheet) {
            PlanEditorView(plan: plan)
        }
        .confirmationDialog("删除后该计划下的所有存入记录也会一起消失，且无法恢复。",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除「\(plan.name)」", role: .destructive) {
                Haptics.warning()
                context.delete(plan)
                try? context.save()
                dismiss()
            }
            Button("取消", role: .cancel) { }
        }
        .onChange(of: plan.savedAmount) { oldValue, newValue in
            let milestones = [0.25, 0.5, 0.75, 1.0]
            let before = plan.targetAmount > 0 ? oldValue / plan.targetAmount : 0
            let after = plan.targetAmount > 0 ? newValue / plan.targetAmount : 0
            if let hit = milestones.first(where: { before < $0 && after >= $0 }) {
                withAnimation { celebrate = true }
                Haptics.celebrate()
                showToast(hit >= 1 ? "目标达成！" : "已完成 \(Int(hit * 100))%")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                    withAnimation { celebrate = false }
                }
            } else {
                Haptics.success()
                showToast("已存入 \(Money.text(newValue - oldValue))")
            }
        }
    }

    // MARK: - 顶部

    private var hero: some View {
        VStack(spacing: Theme.Spacing.m) {
            ProgressRing(progress: plan.progress, tint: color, lineWidth: 16, size: 200) {
                VStack(spacing: Theme.Spacing.xxs) {
                    Text(plan.emoji).font(.system(size: 30))
                    Text(Money.text(plan.savedAmount))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("目标 \(Money.compact(plan.targetAmount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if plan.isCompleted {
                Label("目标已达成", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(color.opacity(0.12), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.l)
        .card(padding: Theme.Spacing.l)
    }

    private var statRow: some View {
        HStack(spacing: Theme.Spacing.s) {
            StatTile(
                title: "还差",
                value: Money.compact(plan.remainingAmount),
                symbol: "flag.checkered",
                tint: color
            )
            StatTile(
                title: plan.daysLeft != nil ? "每天建议" : "已存入笔数",
                value: plan.suggestedDailyAmount.map { Money.text($0.rounded()) } ?? "\(plan.deposits.count) 笔",
                symbol: plan.daysLeft != nil ? "calendar.badge.clock" : "list.bullet.rectangle",
                tint: Theme.amber
            )
        }
    }

    // MARK: - 模式说明

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: plan.mode.symbol)
                    .foregroundStyle(color)
                Text(plan.mode.title).font(.headline)
                Spacer()
                if let deadline = plan.deadline {
                    Text(DateText.short(deadline))
                        .font(.caption)
                        .foregroundStyle(plan.isOverdue ? Theme.danger : .secondary)
                }
            }

            HStack(spacing: Theme.Spacing.m) {
                infoRow("开始", DateText.short(plan.startDate))
                if plan.baseAmount > 0 {
                    infoRow(plan.mode.isFixedAmount ? "每期" : "基数", Money.text(plan.baseAmount))
                }
                if plan.mode.isChallenge {
                    infoRow("总格数", "\(plan.steps.count)")
                }
            }

            if !plan.note.isEmpty {
                Text(plan.note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, Theme.Spacing.xxs)
            }
        }
        .card()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold)).monospacedDigit()
        }
    }

    // MARK: - 打卡网格

    private var checkInCard: some View {
        let steps = plan.steps
        let done = Set(plan.deposits.compactMap(\.stepIndex))
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                SectionHeader(
                    title: "打卡格子",
                    subtitle: "已点亮 \(done.count) / \(steps.count)"
                )
                Spacer()
                let overdue = PlanEngine.overdueStepCount(for: plan)
                if overdue > 0 {
                    Text("逾期 \(overdue) 格")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.danger)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(steps) { step in
                    let isDone = done.contains(step.index)
                    let isOverdue = !isDone && cal.startOfDay(for: step.dueDate) < today

                    Button {
                        guard !isDone else { return }
                        Haptics.tap()
                        depositPrefill = step.amount
                        depositStepIndex = step.index
                        showDepositSheet = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isDone ? color : color.opacity(isOverdue ? 0.16 : 0.07))
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(step.index)")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(isOverdue ? Theme.danger : .secondary)
                            }
                        }
                        .frame(height: 38)
                        .overlay {
                            if isOverdue {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.danger.opacity(0.6), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isDone)
                    .accessibilityLabel("第 \(step.index) 格")
                    .accessibilityValue(isDone ? "已完成" : "\(Money.text(step.amount))，\(isOverdue ? "已逾期" : DateText.short(step.dueDate))")
                }
            }
        }
        .card()
    }

    // MARK: - 进度分段

    private var progressSection: some View {
        VStack(spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                SectionHeader(title: "攒钱节奏")

                if let step = PlanEngine.nextStep(for: plan) {
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(color)
                        Text("下一笔：第 \(step.index) 期 · \(Money.text(step.amount))")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(DateText.short(step.dueDate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if plan.mode.isChallenge {
                    Label("全部格子都点亮了", systemImage: "party.popper.fill")
                        .font(.subheadline)
                        .foregroundStyle(color)
                } else {
                    Text("自由存模式：没有固定节奏，想存就存。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("已完成进度").font(.subheadline)
                    Spacer()
                    Text("\(Int(min(plan.progress, 1) * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(color)
                }

                ProgressView(value: min(plan.progress, 1)).tint(color)

                if let daysLeft = plan.daysLeft {
                    HStack {
                        Text(daysLeft >= 0 ? "距离截止还有" : "已超过截止日期")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(abs(daysLeft)) 天")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(daysLeft < 0 ? Theme.danger : .primary)
                    }
                }
            }
            .card()

            if let deadline = plan.deadline, let daily = plan.suggestedDailyAmount, !plan.isCompleted {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    SectionHeader(title: "达标测算", subtitle: "按截止日期 \(DateText.full(deadline)) 反推")
                    Text("每天存入 \(Money.text(daily.rounded()))，就能按时达成。")
                        .font(.subheadline)
                    Text("也可以选择降低目标金额，或把截止日期往后挪一挪。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .card()
            }
        }
    }

    // MARK: - 记录分段

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            if sortedDeposits.isEmpty {
                EmptyStateView(
                    symbol: "tray",
                    title: "还没有存入记录",
                    message: "点下面的大按钮，存入第一笔。"
                )
                .card()
            } else {
                SectionHeader(title: "存入记录", subtitle: "共 \(sortedDeposits.count) 笔 · 合计 \(Money.text(plan.savedAmount))")

                ForEach(groupedByDay) { group in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(DateText.relative(group.id))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(group.items, id: \.uuid) { record in
                                recordRow(record)
                                if record.uuid != group.items.last?.uuid {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }
                        .card(padding: Theme.Spacing.s)
                    }
                }
            }
        }
    }

    /// 按天分组的存入记录
    private struct DayGroup: Identifiable {
        let id: Date
        let items: [DepositRecord]
    }

    private var groupedByDay: [DayGroup] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: sortedDeposits) { cal.startOfDay(for: $0.date) }
        return grouped
            .map { DayGroup(id: $0.key, items: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.id > $1.id }
    }

    private func recordRow(_ record: DepositRecord) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: record.source.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(record.stepIndex.map { "第 \($0) 期" } ?? record.source.title)
                    .font(.subheadline.weight(.medium))
                if !record.note.isEmpty {
                    Text(record.note).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }

            Spacer()

            Text("+\(Money.text(record.amount))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                Haptics.warning()
                context.delete(record)
                try? context.save()
            } label: {
                Label("删除这笔记录", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(DateText.relative(record.date))存入\(Money.text(record.amount))\(record.note.isEmpty ? "" : "，备注\(record.note)")")
    }

    // MARK: - 底部操作条

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: Theme.Spacing.m) {
                Button {
                    Haptics.tap()
                    depositPrefill = nil
                    depositStepIndex = nil
                    showDepositSheet = true
                } label: {
                    Label("存入一笔", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(color)

                if plan.mode.isChallenge, let step = PlanEngine.nextStep(for: plan) {
                    Button {
                        Haptics.tap()
                        depositPrefill = step.amount
                        depositStepIndex = step.index
                        showDepositSheet = true
                    } label: {
                        VStack(spacing: 0) {
                            Text("下一格").font(.caption2)
                            Text(Money.text(step.amount))
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                        }
                        .frame(minWidth: 88, minHeight: 50)
                    }
                    .buttonStyle(.bordered)
                    .tint(color)
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(.bar)
        }
    }

    // MARK: - Toast

    private func showToast(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { toast = nil }
        }
    }
}
