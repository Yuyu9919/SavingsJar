import SwiftUI
import SwiftData

/// 存入面板：大金额 + 自定义数字键盘 + 快捷金额
struct DepositSheet: View {

    let plan: SavingsPlan
    var prefilledAmount: Double?
    /// 打卡时写入的格子序号
    var stepIndex: Int?

    init(plan: SavingsPlan, prefilledAmount: Double? = nil, stepIndex: Int? = nil) {
        self.plan = plan
        self.prefilledAmount = prefilledAmount
        self.stepIndex = stepIndex
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var showNoteField = false

    private var color: Color { Color(hex: plan.colorHex) }
    private var amount: Double { Double(amountText) ?? 0 }
    private var canSave: Bool { amount > 0 }
    private var isChallengeCheckIn: Bool { stepIndex != nil || (prefilledAmount != nil && plan.mode.isChallenge) }

    private var quickAmounts: [Double] {
        if let step = PlanEngine.nextStep(for: plan), plan.mode.isChallenge {
            return [step.amount, 10, 50, 100]
        }
        return [50, 100, 200, 500]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                amountDisplay
                quickChips

                if showNoteField {
                    noteField
                }

                AmountKeypad(text: $amountText)
                    .padding(.horizontal, Theme.Spacing.m)

                saveButton
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.top, Theme.Spacing.s)
            }
            .padding(.bottom, Theme.Spacing.s)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("存入「\(plan.name)」")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        withAnimation { showNoteField.toggle() }
                    } label: {
                        Image(systemName: showNoteField ? "text.bubble.fill" : "text.bubble")
                    }
                    .accessibilityLabel("添加备注")
                }
            }
            .onAppear {
                if let prefilled = prefilledAmount {
                    amountText = String(format: "%.0f", prefilled)
                }
            }
        }
        .presentationDetents(showNoteField ? Set<PresentationDetent>([.large])
                                            : Set<PresentationDetent>([.fraction(0.72), .large]))
        .presentationDragIndicator(.visible)
    }

    // MARK: - 金额展示

    private var amountDisplay: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(isChallengeCheckIn ? "本次打卡金额" : "存入金额")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Money.symbol)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(amountText.isEmpty ? "0" : amountText)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(canSave ? color : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(height: 56)
            .animation(.snappy, value: amountText)

            HStack(spacing: Theme.Spacing.s) {
                Text("存入后：\(Money.text(plan.savedAmount + amount)) / \(Money.compact(plan.targetAmount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if plan.targetAmount > 0, plan.savedAmount + amount >= plan.targetAmount {
                    Text("达成")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.15), in: Capsule())
                        .foregroundStyle(color)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.s)
    }

    // MARK: - 快捷金额

    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                ForEach(quickAmounts, id: \.self) { value in
                    Button {
                        Haptics.tap()
                        amountText = String(format: "%.0f", value)
                    } label: {
                        Text("+\(Money.text(value))")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, Theme.Spacing.m)
                            .frame(minHeight: 38)
                            .background(color.opacity(0.12), in: Capsule())
                            .foregroundStyle(color)
                    }
                    .buttonStyle(.plain)
                }

                if plan.remainingAmount > 0 {
                    Button {
                        Haptics.tap()
                        amountText = String(format: "%.0f", plan.remainingAmount)
                    } label: {
                        Text("补齐差额")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, Theme.Spacing.m)
                            .frame(minHeight: 38)
                            .background(Theme.amber.opacity(0.16), in: Capsule())
                            .foregroundStyle(Theme.amber)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.s)
        }
    }

    private var noteField: some View {
        VStack(spacing: Theme.Spacing.s) {
            TextField("备注，如「发了年终奖」", text: $note)
                .textFieldStyle(.plain)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(minHeight: Theme.minTouch)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))

            DatePicker("日期", selection: $date, displayedComponents: .date)
                .padding(.horizontal, Theme.Spacing.m)
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
    }

    // MARK: - 保存

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text(isChallengeCheckIn ? "点亮这一格" : "确认存入")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .disabled(!canSave)
    }

    private func save() {
        guard amount > 0 else { return }
        let record = DepositRecord(
            amount: amount,
            date: date,
            note: note.trimmingCharacters(in: .whitespaces),
            source: stepIndex != nil ? .checkIn : (prefilledAmount != nil ? .quickAdd : .manual),
            stepIndex: stepIndex,
            plan: plan
        )
        context.insert(record)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
