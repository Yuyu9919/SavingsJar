import SwiftUI
import SwiftData

/// 计划列表：支持搜索、状态筛选、滑动归档 / 删除
struct PlansView: View {

    enum Filter: String, CaseIterable, Identifiable {
        case active, completed, archived
        var id: String { rawValue }
        var title: String {
            switch self {
            case .active:    return "进行中"
            case .completed: return "已完成"
            case .archived:  return "已归档"
            }
        }
    }

    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\SavingsPlan.createdAt, order: .reverse)])
    private var allPlans: [SavingsPlan]

    @State private var filter: Filter = .active
    @State private var keyword = ""

    private var filtered: [SavingsPlan] {
        allPlans.filter { plan in
            let statusOK: Bool
            switch filter {
            case .active:    statusOK = !plan.isArchived && !plan.isCompleted
            case .completed: statusOK = !plan.isArchived && plan.isCompleted
            case .archived:  statusOK = plan.isArchived
            }
            let keywordOK = keyword.isEmpty
                || plan.name.localizedCaseInsensitiveContains(keyword)
                || plan.note.localizedCaseInsensitiveContains(keyword)
            return statusOK && keywordOK
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.m) {
                Picker("状态", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("计划状态筛选")

                if filtered.isEmpty {
                    EmptyStateView(
                        symbol: filter == .archived ? "archivebox" : "target",
                        title: filter == .archived ? "没有归档的计划" : "这里还没有计划",
                        message: filter == .active ? "开一个计划，给它起个名字，比如「北海道旅行基金」。" : "换个筛选条件看看。",
                        actionTitle: filter == .active ? "新建计划" : nil
                    ) { app.isPresentingPlanEditor = true }
                    .card()
                } else {
                    ForEach(filtered) { plan in
                        NavigationLink {
                            PlanDetailView(plan: plan)
                        } label: {
                            PlanCard(plan: plan, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                Haptics.tap()
                                plan.isArchived.toggle()
                            } label: {
                                Label(plan.isArchived ? "取消归档" : "归档", systemImage: "archivebox")
                            }
                            Button(role: .destructive) {
                                delete(plan)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $keyword, prompt: "搜索计划名称或备注")
        .navigationTitle("攒钱计划")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    app.isPresentingPlanEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新建攒钱计划")
            }
        }
    }

    private func delete(_ plan: SavingsPlan) {
        Haptics.warning()
        context.delete(plan)
        try? context.save()
    }
}
