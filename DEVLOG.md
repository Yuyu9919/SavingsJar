# 开发日志与项目上下文

> **这份文件的作用**：让任何一台电脑（或任何一次新的 AI 会话）在 `git clone` 之后，
> 能立刻理解这个项目已经决定了什么、踩过哪些坑、下一步该做什么。
>
> **约定**：每次收工前，在下面的「进度日志」里追加一行。这样换电脑、换会话都不会丢上下文。

---

## 一、项目是什么

**攒钱罐（SavingsJar）** —— iOS 原生攒钱 App。核心差异点是**一个 App 里可以同时跑任意多个互不干扰的储蓄计划**。

- 技术栈：SwiftUI + SwiftData，iOS 17+，**零第三方依赖**
- 数据：全部存本地，**不联网、不上传、无账号**
- 阶段：功能开发完成，正在准备真机测试 → 上架

## 二、开发者的环境约束（很重要，别默认本地能编译）

| 约束 | 影响 |
|---|---|
| **只有 Windows，没有 Mac** | 无法本地编译 iOS。必须走云端构建（GitHub Actions / Codemagic） |
| 有 iPhone | 可以走免费 Apple ID 侧载做真机测试 |
| 主力编辑器是 WorkBuddy | 换电脑时工作区路径会变，所以文档里**不写死绝对路径** |

**工作流原则：改 UI 先在 `preview.html` 里改，满意后再同步到 Swift。**
Windows 上每轮 Swift 改动要 10 分钟（推代码 → 云构建 → 侧载），HTML 改颜色只要 2 秒。

## 三、关键技术决策（改代码前先读，避免踩回同一个坑）

1. **SwiftData 的 `@Model` 里不能声明名为 `id` 的属性** —— 会和 `PersistentModel` 的
   `Identifiable` 冲突。模型里统一用 `uuid: String`。
2. **Swift 的 key path 不能指向元组元素** —— `ForEach(data, id: \.key)` 会编译失败。
   图表和分组数据一律先定义成 `Identifiable` 结构体（`DailyTotal`、`DayGroup`）。
3. **`Color.gradient` 返回 `AnyGradient`**，和 `LinearGradient` 在三元表达式里类型不一致。
   统一用 `LinearGradient`。
4. **彩带用 `TimelineView` 常驻动画会拖慢滚动** —— 只在 `isActive` 时才渲染。
5. **一级导航用 TabView 四页**（总览 / 计划 / 挑战 / 我的），不用汉堡菜单。
6. **挑战类计划用「格子打卡」网格**表达节奏，逾期格子描红边。

## 四、文件地图

```
SavingsJar/
├── SavingsJar/                  ← Xcode 工程源码（Swift）
│   ├── Models/                  SavingsPlan / DepositRecord / SavingsMode
│   ├── Services/                PlanEngine（时间表·达标测算·连续打卡）/ Haptics / NotificationManager
│   ├── DesignSystem/            Theme（配色·间距·金额格式化）/ Components（进度环·卡片·数字键盘·彩带·柱状图）
│   ├── Views/                   Root / Dashboard / Plans / PlanDetail(打卡网格) / PlanEditor
│   │                            / DepositSheet / Challenges / Profile / Onboarding
│   └── Resources/Assets.xcassets  AppIcon + AccentColor(#12B886)
├── preview.html                 ★ 浏览器高保真原型（改设计先改这里）
├── project.yml                  XcodeGen 工程描述（不手工建 .xcodeproj）
├── .github/workflows/
│   ├── ios-build.yml            云构建：未签名 IPA（侧载自用）
│   └── ios-release.yml          云构建：签名归档 + 上传 TestFlight（上架用）
├── codemagic.yaml               Codemagic 备选（网页操作，含 ios-app-store workflow）
├── tools/make_icon.py           图标生成脚本（Pillow，改配色重跑即可）
├── AppStore/                    上架材料（详见该目录）
├── README.md                    项目说明 + 文档导航
├── TESTING.md                   ★ 四级测试阶梯 + 8 组 QA 清单
├── SIDELOAD-GUIDE.md            ★ 从 Windows 到 iPhone 的侧载全流程
├── APPSTORE-LAUNCH.md           ★ 上架与运营总手册
├── BUILD-WITHOUT-MAC.md         无 Mac 构建的五条路线对比
└── WORK-ACROSS-DEVICES.md       换电脑怎么衔接
```

## 五、产品设计约定

| 项 | 值 |
|---|---|
| 品牌主色 | `#12B886` 薄荷绿（代表增长） |
| 强调色 | `#FFB703` 琥珀（代表金币） |
| 危险色 | `#EF476F` |
| 间距 | 8pt 网格：2 / 4 / 8 / 16 / 24 / 32 |
| 圆角 | chip 10 · field 14 · card 20 · sheet 28 |

**五种储蓄节奏**：自由存 / 定额存 / 52 周挑战（¥13,780）/ 365 天挑战（¥66,795）/ 阶梯递增

## 六、当前进度与待办

### 已完成
- [x] 完整 SwiftUI + SwiftData 工程（约 3270 行，零依赖）
- [x] `preview.html` 可点击原型
- [x] 无 Mac 构建方案（GitHub Actions + Codemagic）
- [x] 上架全套材料（元数据 / 隐私政策 / 支持页 / 提审清单）
- [x] App 图标（占位版）+ 生成脚本
- [x] 侧载指南、测试方案
- [x] git 仓库初始化（`main` 分支）

### 待办（按优先级）
- [ ] **推送代码到 GitHub，跑通第一次云构建**（首要任务）
- [ ] 真机侧载，按 `TESTING.md` 的 A~H 清单逐条验收
- [ ] 修第一批 Bug
- [ ] 替换正式版 App 图标（当前是占位）
- [ ] 注册 Apple 开发者账号 + 申请小企业计划
- [ ] TestFlight 内测
- [ ] 提审

### 已知待确认
- **iPhone 的 iOS 版本是否 ≥ 17**。低于 17 需要把数据层从 SwiftData 降级为 JSON 存储。

## 七、进度日志

| 日期 | 做了什么 |
|---|---|
| 2026-10-10 | 完成工程主体（18 个 Swift 文件）。产出浏览器原型。确定无 Mac 构建方案。 |
| 2026-10-10 | 完成上架材料全套（APPSTORE-LAUNCH / metadata / review-checklist / 隐私政策 / 支持页）。确认 2026/4/28 起必须 Xcode 26 + iOS 26 SDK 构建。 |
| 2026-10-10 | 产出测试方案（四级阶梯 + QA 清单）。修复 ios-build.yml 的 runner 写死问题。 |
| 2026-10-10 | 生成占位 App 图标 + `tools/make_icon.py`。初始化 git 仓库。产出侧载指南。 |
| 2026-10-10 | 产出跨设备工作流方案。清理文档里的绝对路径。 |

<!-- 在这里追加新的一行，不要删除上面的记录 -->
