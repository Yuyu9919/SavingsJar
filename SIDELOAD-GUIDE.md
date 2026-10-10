# 从这台 Windows 到你的 iPhone —— 侧载完整指南

> 目标：不花一分钱，把攒钱罐装到你自己的 iPhone 上跑起来。
> 全程大约 1 小时（大部分时间在等下载和云构建）。
>
> 前置条件：一台 iPhone + 数据线 + 这台 Windows 电脑。

---

## 第 0 步 · 先确认 iOS 版本（1 分钟，决定整个方案成不成立）

iPhone 上：**设置 ▸ 通用 ▸ 关于本机 ▸ 系统版本**

| 你的版本 | 结论 |
|---|---|
| **iOS 17.0 及以上** | ✅ 直接按本指南走，什么都不用改 |
| **iOS 16.x 及以下** | ⚠️ 工程用了 SwiftData（要求 iOS 17+），装不上。**先告诉我，我把数据层降级成 JSON 存储**，大约半小时的改动量 |

顺便看一眼机型：iPhone 8 / X 及更早的机型最高只能到 iOS 16，属于上表第二行。

---

## 第 1 步 · 把代码推上 GitHub（约 10 分钟）

本地仓库我已经初始化好了（`main` 分支，`.gitignore` 已配好）。
你需要做三件事：

### 1.1 告诉 git 你是谁（只需做一次）

把下面两行的引号里换成你自己的，然后在 `SavingsJar` 目录下执行：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

> 邮箱建议用你在 GitHub 注册的那个。如果你不想暴露真实邮箱，
> GitHub 提供了匿名格式：`ID+用户名@users.noreply.github.com`（在 GitHub 邮件设置里能看到）。

### 1.2 在 GitHub 上建一个空仓库

1. 打开 <https://github.com/new>
2. Repository name：`SavingsJar`
3. 选 **Public**（关键：公有仓库的 macOS 构建分钟数**完全免费**，私有仓库每月只有 2000 分钟且 macOS 按 10 倍扣）
4. **什么都不要勾**——不要 README、不要 .gitignore、不要 License（本地已经有了）
5. 点 **Create repository**

### 1.3 推上去

在 `SavingsJar` 目录下执行（换掉你的用户名）：

```bash
git add .
git commit -m "feat: 攒钱罐 v0.1 首次提交"
git remote add origin https://github.com/<你的用户名>/SavingsJar.git
git push -u origin main
```

> 推送时会弹 GitHub 登录窗口（浏览器授权），跟着点就行。
> 如果没弹窗而是要密码：**密码栏填 Personal Access Token，不是账号密码**
> （GitHub 早就不支持密码推送了。Token 在 GitHub ▸ Settings ▸ Developer settings ▸ Tokens 里生成，勾 `repo` 权限）。

#### 生成 Personal Access Token（30 秒，只做一次）

1. 打开 <https://github.com/settings/tokens> → **Generate new token** → 选 **Tokens (classic)**
2. Note 填 `SavingsJar`，Expiration 选 **90 days**（到期重新生成即可）
3. 勾选权限：只勾最上面那个 **`repo`**（整组）就够
4. 拉到底点 **Generate token** → **立刻复制**那串 `ghp_...`
   （离开页面就再也看不到了，丢了只能重新生成）

推送时如果提示 `Username`：填 `Yuyu9919`；提示 `Password`：**粘贴 token**（不是账号密码）。
Windows 上凭证会被「凭据管理器」记住，之后不用重复输入。

#### 如果 push 被拦住（公司网络常见）

症状：卡住不动、`CONNECT tunnel failed, response 502`、SSL 证书错误、`Connection reset`。
说明网络策略不允许访问 github.com。三条退路：

| 退路 | 做法 | 适合 |
|---|---|---|
| **换网络** | 用手机热点推一次 | 最快验证 |
| **GitHub Desktop** | 装 <https://desktop.github.com/>，图形界面登录 → Add local repository → Publish | 不熟命令行的人，最省事 |
| **换到家里电脑推** | 见 `WORK-ACROSS-DEVICES.md`，把项目拷过去再推 | 长期方案 |

---

## 第 2 步 · 云端构建，拿到 IPA（约 8 分钟，全自动）

1. 打开你仓库的 **Actions** 标签页
   （如果页面提示 workflows 被禁用，点 **I understand my workflows, go ahead and enable them**）
2. 左侧选 **Build iOS**，应该有一次刚触发的运行在转圈
3. 等它变绿 ✅（首次约 5~8 分钟：要装 XcodeGen、下载工具链）
4. 点进这次运行，拉到页面最底部的 **Artifacts** 区域
5. 下载 **`SavingsJar-unsigned-ipa`**，解压得到 `SavingsJar-unsigned.ipa`

> ❌ 如果红了：点进去看报错日志，把最后 30 行发给我，我来修。
> 常见错误对照表在 `TESTING.md` 的 L1 一节。

---

## 第 3 步 · Windows 上装两个软件（约 15 分钟，主要是下载）

| 软件 | 从哪下 | 注意 |
|---|---|---|
| **Sideloadly** | [sideloadly.io](https://sideloadly.io) | Windows 版，装完桌面会有图标 |
| **iTunes** | **apple.com 官网** <https://www.apple.com/itunes/> | ⚠️ **千万别用 Microsoft Store 版！** Store 版没有 Apple Mobile Device USB 驱动，Sideloadly 会认不到手机。这是新手第一大坑 |
| （可选）iCloud | 同上官网 | 部分 Windows 精简系统缺它的驱动组件，装上更稳 |

装完 iTunes 后**用数据线连接 iPhone**，手机上弹「要信任此电脑吗」→ 点**信任**并输锁屏密码。

验证连接：打开 Sideloadly，顶部下拉框里能看到你的 iPhone 型号就说明驱动 OK。

---

## 第 4 步 · 签名并安装（约 5 分钟）

### 4.1 先生成一个「App 专用密码」（强烈建议，别跳过）

用 Apple 主密码直接签，遇到双重认证经常失败。App 专用密码能绕开这个坑：

1. 打开 <https://appleid.apple.com> 登录
2. **登录与安全 ▸ App 专用密码 ▸ 生成密码**
3. 起个名字（如 `sideloadly`），点创建
4. **复制弹出的密码**（`xxxx-xxxx-xxxx-xxxx` 格式，只显示这一次）

### 4.2 签名

1. 打开 Sideloadly
2. 把 `SavingsJar-unsigned.ipa` 拖进窗口
3. **Apple ID** 填你的 Apple ID 邮箱
4. **Password** 填刚才的 App 专用密码
5. 其他选项保持默认，点 **Start**
6. 等 1~3 分钟，看到绿色完成提示

---

## 第 5 步 · 手机上放行（两处设置，缺一不可）

### 5.1 信任开发者证书

**设置 ▸ 通用 ▸ VPN与设备管理**
→ 找到你的 Apple ID（显示为「开发者 App」）→ 点**信任**

### 5.2 打开开发者模式（iOS 16+ 必做，90% 的人卡在这）

**设置 ▸ 隐私与安全性 ▸ 开发者模式** → 打开 → **重启手机**

> 找不到这个开关？两个原因：
> ① 列表要**往下滚**，它在页面下部；
> ② 没装任何开发签名的 App 时这个开关是隐藏的——所以先完成 5.1 再看。

重启后桌面上的**攒钱罐**图标就能点开了。🎉

---

## 第 6 步 · 解决「7 天闪退」（可选但强烈建议）

免费签名的 App **7 天后过期**，点开即闪退。两个办法：

### 办法一：手动重签（简单粗暴）

7 天内连一次电脑，Sideloadly 里重复第 4 步。**数据不会丢**，放心签。

### 办法二：AltStore 自动续签（一劳永逸，推荐）

1. Windows 上安装 **AltServer**：<https://altstore.io>（Sideloadly 和 AltServer 共存没冲突）
2. AltServer 常驻后台，用**同一个 Apple ID** 先把 AltStore 装到手机上
3. 以后每 7 天，只要**手机和电脑连着同一个 Wi-Fi**，就会自动后台续签
4. 注意：电脑得开着（休眠也行），彻底关机几天就不保证了

### 三个限制提前知道

| 限制 | 说明 |
|---|---|
| 最多 3 个自签 App | 装第 4 个会报错，删掉不用的即可 |
| 7 天过期 | 见上 |
| 数据安全 | 过期只是签名失效，重签后所有数据原样保留 |

---

## 日常迭代循环（配好之后每轮长这样）

```
改 Swift 代码
   ↓  ① git add . && git commit -m "..." && git push
GitHub Actions 自动构建（5~8 分钟，可去干别的）
   ↓  ② Actions 页面下载新的 .ipa
Sideloadly 重签（1~3 分钟，手机连着线即可）
   ↓  ③ 手机上直接覆盖安装，数据保留
真机验证
```

一轮大约 **10 分钟**。所以还是那句话：**UI 细节先在 `preview.html` 里调**，
攒一批改动再走这个循环，别一行一行地等构建。

---

## 卡点速查

| 现象 | 原因 | 解法 |
|---|---|---|
| Sideloadly 下拉框里没有手机 | 装了 Microsoft Store 版 iTunes | 卸载 → 装 apple.com 官网版 → 重插数据线 |
| Sideloadly 报 `GVA` 或密码错误 | 用了主密码 + 双重认证冲突 | 换 App 专用密码（第 4.1 节） |
| 手机上没出现 App 图标 | 安装中途失败 | 看 Sideloadly 日志；常见是 IPA 损坏，重新下载 artifact |
| App 图标是灰的/点不开 | 没信任证书 | 第 5.1 步 |
| 提示「不受信任的开发者」弹窗 | 同上 | 第 5.1 步 |
| 找不到「开发者模式」开关 | 没先信任证书，或没往下滚 | 先做 5.1，再在隐私与安全性页**往下滚** |
| 装了几天后闪退 | 7 天签名到期 | 重签 / AltStore 自动续签 |
| 重签后数据没了 | （不应发生）若发生，说明删了 App 重装而不是覆盖安装 | Sideloadly 覆盖安装不丢数据；**删了重装会丢** |
| git push 要密码 | GitHub 不支持密码 | 用 Personal Access Token（第 1.3 节） |
| Actions 没有自动跑 | workflows 被禁用了 | Actions 页面点启用 |

---

## 到这一步之后

真机跑起来后，打开 `TESTING.md`，从 **A 组（五种节奏建计划）** 开始逐条打勾，
一直测到 H 组（首次启动体验）。发现问题随时丢给我，HTML 和 Swift 两边我一起改。
