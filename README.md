# 攒钱罐（SavingsJar）

一个 **iOS 原生攒钱 App**：把攒钱拆成很多个互不干扰的独立计划，每个计划可以有自己的目标、节奏、图标和颜色。

- 技术栈：SwiftUI + SwiftData（iOS 17+），MVVM，零第三方依赖
- 设计规范：Apple HIG，8pt 网格，44pt 触控目标，Dynamic Type，VoiceOver 标签齐全
- 数据：全部落在本机 SwiftData，不联网、不上传

---

## 文档导航

| 想做什么 | 看哪个文件 |
|---|---|
| 跑起来看看效果 | `preview.html`（浏览器直接打开，可点击体验） |
| **上架 App Store 全流程** | **`APPSTORE-LAUNCH.md`** ← 主文档 |
| **前期怎么测试（从 0 元到 TestFlight）** | **`TESTING.md`** |
| **把 App 装到自己 iPhone 上（侧载指南）** | **`SIDELOAD-GUIDE.md`** |
| **换电脑怎么衔接（工作电脑 ⇄ 家里）** | **`WORK-ACROSS-DEVICES.md`** |
| **开新会话前先读这个** | **`DEVLOG.md`**（项目上下文与技术决策） |
| App Store Connect 该填什么 | `AppStore/metadata.md`（文案可直接复制） |
| 提审前自检 / 被拒了怎么办 | `AppStore/review-checklist.md` |
| 隐私政策页 / 技术支持页 | `AppStore/privacy-policy.html`、`AppStore/support.html` |
| 没有 Mac 怎么构建 | `BUILD-WITHOUT-MAC.md`、`project.yml`、`codemagic.yaml` |

---

## 一、核心概念

| 概念 | 说明 |
|---|---|
| **计划（Plan）** | 一个独立的攒钱目标。可以同时跑任意多个 |
| **节奏（Mode）** | 每期该存多少的规则：自由存 / 定额存 / 52 周 / 365 天 / 阶梯递增 |
| **格子（Step）** | 有节奏的计划会被自动排成一张时间表，每格对应一天 / 一周 / 一月 |
| **存入（Deposit）** | 一笔入账记录，可手动存，也可通过点亮格子存入 |

一个计划 = 名称 + 图标 + 颜色 + 目标金额 + 节奏 + 截止日期（可选）+ 备注 + 每日提醒。

---

## 二、功能清单

**总览（Dashboard）**
- 累计已攒金额 + 整体完成度进度环
- 「今天该存 xx 元」待办卡，一键跳转打卡
- 近 7 天存入柱状图
- 进行中计划卡片列表、连续打卡天数

**计划（Plans）**
- 搜索 + 状态筛选（进行中 / 已完成 / 已归档）
- 长按卡片：归档 / 删除
- 显示剩余天数，逾期标红

**计划详情（Detail）**
- 大进度环 + 还差多少 + 每日建议金额
- 目标模式说明卡（开始日期、每期基数、总格数）
- **打卡网格**：挑战类计划把每一格排出来，点一下即存入对应金额，逾期格子描红
- 进度 / 记录两个分段：达标测算、按天分组的存入流水（长按删除）
- 进度跨越 25% / 50% / 75% / 100% 时触发彩带 + 强触觉反馈

**挑战（Challenges）**
- 5 个预置模板：52 周存钱挑战、365 天存钱挑战、12 月阶梯存、每天 10 元、每月 500 元
- 一键生成计划，自动排好全部日期与总目标
- 列出所有进行中的挑战及其点亮进度

**我的（Profile）**
- 累计攒下 / 计划总数 / 已完成 / 连续天数
- 近 30 天存入柱状图、最长连续天数
- 设置：货币符号、触觉反馈、每日提醒（本地通知）
- 导出全部记录为 CSV（系统分享面板）

**存入面板（DepositSheet）**
- 顶部实时显示「存入后 x / 目标」
- 快捷金额胶囊（下一格金额、+50、+100…、补齐差额）
- 自定义大号数字键盘（最多两位小数）
- 可选备注与日期

---

## 三、目录结构

```
SavingsJar/
├── SavingsJar/
│   ├── SavingsJarApp.swift          App 入口 / ModelContainer 装配
│   ├── Models/
│   │   ├── SavingsMode.swift        攒钱节奏枚举 + 周期单位
│   │   ├── SavingsPlan.swift        计划（SwiftData @Model）
│   │   └── DepositRecord.swift      存入记录（SwiftData @Model）
│   ├── Services/
│   │   ├── PlanEngine.swift         时间表生成 / 达标测算 / 连续打卡统计
│   │   ├── Haptics.swift            触觉反馈统一入口
│   │   └── NotificationManager.swift 本地通知
│   ├── DesignSystem/
│   │   ├── Theme.swift              颜色 / 间距 / 圆角 / 金额格式化
│   │   └── Components.swift         进度环、计划卡、键盘、彩带、迷你柱状图…
│   └── Views/
│       ├── RootView.swift           TabView + 全局 AppState
│       ├── DashboardView.swift      总览
│       ├── PlansView.swift          计划列表
│       ├── PlanDetailView.swift     计划详情（含打卡网格）
│       ├── PlanEditorView.swift     新建 / 编辑计划
│       ├── DepositSheet.swift       存入面板
│       ├── ChallengesView.swift     挑战模板
│       ├── ProfileView.swift        我的（统计 + 设置）
│       └── OnboardingView.swift     首次启动引导
└── preview.html                     可在浏览器点击体验的高保真原型
```

---

## 四、怎么跑起来

1. 安装 **Xcode 15** 或更高版本（需要 macOS），确保已安装 iOS 17 模拟器。
2. Xcode → `File ▸ New ▸ Project… ▸ iOS ▸ App`
   - Product Name：`SavingsJar`
   - Interface：**SwiftUI**
   - Storage：**SwiftData**
   - Language：**Swift**
3. 删掉模板自带的 `ContentView.swift` 和 `SavingsJarApp.swift`。
4. 把本目录 `SavingsJar/SavingsJar/` 下的 5 个文件夹（`Models`、`Services`、`DesignSystem`、`Views` 与 `SavingsJarApp.swift`）整体拖进 Xcode 工程，勾选 *Copy items if needed* 与 *Create groups*。
5. 选中 Target ▸ Signing & Capabilities，填上自己的 Team（真机需要）。
6. `⌘R` 运行。

> 不需要任何第三方依赖，不需要网络权限。通知权限只在用户主动打开「每日提醒」开关时才会请求。

---

## 五、几个设计决策

- **不用汉堡菜单**：四个一级入口用 TabView 承载（总览 / 计划 / 挑战 / 我的）。
- **不覆盖系统返回手势**：详情页全部走 `NavigationStack` 原生返回。
- **不在启动时弹权限**：通知权限延后到用户打开提醒开关时请求。
- **不依赖颜色单独传达信息**：逾期格子既有红色描边，也有编号变红的文字提示；完成态同时有对勾。
- **不用全屏 loading**：SwiftData 本地读取，无需骨架屏。
- **Modal 一定可退出**：所有 sheet 都带「取消」按钮并支持下滑关闭。
- **金额只用等宽数字**（`.monospacedDigit()`），避免数字跳动。

---

## 六、可以继续加的

- **WidgetKit**：桌面小组件显示「今天该存多少」与单个计划的进度环
- **iCloud / CloudKit 同步**：把 `ModelConfiguration` 换成 `cloudKitDatabase:` 即可多设备同步
- **Live Activity**：挑战进行中在锁屏显示当前格子
- **App Intents / 快捷指令**：语音「往旅行基金存 100」
- **Face ID 锁**：给攒钱数据加一层生物识别保护
