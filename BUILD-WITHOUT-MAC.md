# 没有 Mac，怎么把「攒钱罐」跑起来

一句话原理：**iOS 的编译器（Xcode / xcodebuild）只能在 macOS 上运行，Windows 上装不了、也模拟不了。** 所以思路只有两个——要么「借一台 Mac」，要么「把编译丢到云端」，最后把产物拿回 Windows 装进 iPhone。

---

## 一、五条路线怎么选

| 路线 | 花钱 | 能看到什么 | 难度 | 适合谁 |
|---|---|---|---|---|
| **A. 云端 CI 构建 + 侧载**（推荐） | 0 元 | iPhone 真机上跑完整 App | 中 | 想真在手机上用 |
| **B. 租一台云 Mac** | 约 ¥7/小时 或 ¥180/月起 | 完整 Xcode + 模拟器，边改边看 | 中 | 要长期改代码 |
| **C. Appetize 浏览器体验** | 0 元（100 分钟/月） | 浏览器里点着玩，不用 iPhone | 低 | 只想先看看效果 |
| **D. iPad + Swift Playgrounds** | 需要一台 iPad | iPad 上直接运行 | 中 | 手边有 iPad |
| **E. 改写成 Expo / Flutter** | 0 元 | 手机扫码即用 | 高（要重写全部代码） | 以后想双端都做 |

> 最新的 iOS 版 Swift / SwiftUI / SwiftData 都是 macOS 独占工具链，Windows 上没有合法替代品。这是 Apple 的限制，不是工具问题。

**建议组合：先用 C 在浏览器里看效果 → 满意了走 A 装到手机上。**

---

## 二、路线 A：云端构建 + 侧载（0 元，全流程在 Windows 完成）

我已经把需要的配置文件都放好了：

- `project.yml` —— 工程描述（不用手工建 `.xcodeproj`）
- `.github/workflows/ios-build.yml` —— GitHub 的云端构建脚本
- `codemagic.yaml` —— Codemagic 的云端构建脚本（备选，界面更好看）

### 第 0 步：准备

- 一个 **GitHub 账号**（免费注册）
- 一台 **iPhone，系统 iOS 17 或更高**（App 用了 SwiftData，最低 iOS 17）
- 一根数据线
- 一个 **Apple ID**（免费账号就够，不用花钱）

### 第 1 步：把代码推到 GitHub

在 Windows 的 Git Bash 里执行（把 `<你的用户名>` 换成自己的）：

```bash
# 在项目根目录（SavingsJar/）执行
git add .
git commit -m "feat: 攒钱罐 iOS App"

# 先在 github.com 网页上新建一个空仓库（不要勾选 README），名字叫 SavingsJar
git remote add origin https://github.com/<你的用户名>/SavingsJar.git
git branch -M main
git push -u origin main
```

> 推上去之后 Actions 会自动跑一次。也可以手动触发。

### 第 2 步：等云端 Mac 帮你编译

1. 打开 `https://github.com/<你的用户名>/SavingsJar/actions`
2. 看到 **Build iOS** 这条 workflow，点进去 → 点 **Run workflow**（或等它自动跑）
3. 大约 5~8 分钟后变成绿色 ✅
4. 页面底部 **Artifacts** 区域，下载：
   - `SavingsJar-unsigned-ipa` → 解压得到 **`SavingsJar-unsigned.ipa`**（给 iPhone 用）
   - `SavingsJar-simulator` → 给路线 C 用

> **免费额度**：GitHub 免费版每月 2000 分钟，但 macOS 机器按 **10 倍**计费，等于约 200 分钟 ≈ 每月能构建 25~40 次。够用了。
> 想让额度翻倍：把仓库设为 **Public**，macOS 分钟完全免费。

### 第 3 步：在 Windows 上把 ipa 装进 iPhone（Sideloadly）

免费 Apple ID 不能上架，但可以「自签」安装 7 天。

1. **装驱动**：去 Apple 官网下载安装 **iTunes（官网版，不要用微软商店版）**。它会带上 Sideloadly 需要的 USB 驱动和设备通信库。
2. **装工具**：下载 [Sideloadly](https://sideloadly.io/)（Windows 版），安装。
3. **连手机**：数据线插上 iPhone，手机弹窗点「**信任此电脑**」。
4. **开始签**：
   - Sideloadly 顶部会自动出现你的设备
   - 把 `SavingsJar-unsigned.ipa` 拖到中间的 **IPA** 框
   - **Apple Account** 填你的 Apple ID
   - 点 **Start**
   - 会要求输入 Apple ID 密码；如果开了双重认证，手机会弹出验证码，填进去
5. **信任证书**：手机上 → `设置 ▸ 通用 ▸ VPN与设备管理` → 找到 `Apple Development: 你的邮箱` → 点「**信任**」
6. **开启开发者模式**（iOS 16+ 必做，很多人卡在这一步）：
   `设置 ▸ 隐私与安全性 ▸ 开发者模式` → 打开 → **重启手机** → 重启后确认开启

搞定，桌面上就有「攒钱罐」了。

### 第 4 步：7 天过期怎么办

免费签名有效期只有 7 天，过期后 App 打不开（**数据不会丢**，沙盒还在）。

- **手动续签**：重新跑一遍 Sideloadly 步骤 3~6，直接覆盖安装，数据保留。
- **自动续签（推荐）**：装 [AltStore](https://altstore.io/) 的 **AltServer** 到 Windows，同一 Wi-Fi 下它会每 7 天自动帮你重签，不用插线。

### 免费账号的三个限制（提前知道不踩坑）

| 限制 | 数值 |
|---|---|
| 签名有效期 | 7 天 |
| 同时存在的自签 App | 最多 3 个 |
| 能上架 App Store / TestFlight | 不能 |

### 什么时候该花那 99 美元

如果你打算**长期自己用**（不想每 7 天续签）、或者**给别人用**（亲友、同事），就买 Apple Developer Program（$99/年）：

- 证书有效期 1 年
- 可以走 **TestFlight**：上传后生成邀请链接，别人手机上直接装，不用连电脑
- 可以上架 App Store（需要审核，约 1~3 天）

买了之后在 `project.yml` 里填上 `DEVELOPMENT_TEAM`，再把 workflow 里的 `CODE_SIGNING_ALLOWED=NO` 换成正式签名即可，我可以帮你改。

---

## 三、路线 B：租一台云 Mac（最接近"我真的有台 Mac"）

适合：你想**持续修改代码**、需要在 iOS 模拟器里反复调试。

| 服务商 | 价格参考 | 说明 |
|---|---|---|
| [MacinCloud](https://www.macincloud.com/) | 按小时约 $1/h，月付 $25 起 | 最常用，支持按需付费 |
| [MacStadium](https://www.macstadium.com/) | 月付 $79 起 | 更稳，偏企业 |
| AWS EC2 Mac 实例 | 约 $0.65/h 起 | 需要专用主机，最少 24 小时起租 |
| 国内云 Mac 服务商 | 按天/按月 | 搜「云 Mac 租用」，选离你近的机房延迟更低 |

连上之后：

```bash
brew install xcodegen
cd SavingsJar
xcodegen generate
open SavingsJar.xcodeproj      # 直接开始写代码、跑模拟器
```

Windows 上用 **Microsoft Remote Desktop** 或 **VNC Viewer** 远程桌面过去，体验接近本地。

> 提示：Xcode 首次安装约 10~15 GB，租按小时的机器时记得先算好下载时间，或者选"已预装 Xcode"的镜像。

---

## 四、路线 C：不装手机，直接在浏览器里体验

不用 iPhone、不用签名，浏览器里就是一个可点的手机。

1. 从 GitHub Actions 下载 `SavingsJar-simulator` 解压得到 `SavingsJar.app`
2. 打包成 zip（Windows 右键 → 压缩成 zip，**必须保留 .app 目录结构**）
3. 打开 [appetize.io](https://appetize.io/) → 上传 zip → 得到一个链接
4. 打开链接就能在浏览器里点着玩

> 免费版每月 100 分钟。**如果只是想看效果，其实直接用我已经做好的 `preview.html` 更快**——它本来就是按同一套交互画的高保真原型。

---

## 五、路线 D：iPad + Swift Playgrounds（手边有 iPad 的话）

iPad 上的 **Swift Playgrounds 4** 可以直接创建、运行 iOS App，甚至提交 App Store，全程不需要 Mac。

- 代价：工程格式是 `.swiftpm`，和我现在给的 Xcode 工程格式不同，需要转换一下（入口文件、资源组织方式有差异）
- 用 `project.yml` 里的 `sources: SavingsJar` 那套结构，转换成 Swift Playgrounds App 包大概需要十几分钟

**如果你有 iPad，跟我说一声，我直接把工程转成 Swift Playgrounds 能打开的格式。**

---

## 六、常见报错对照表

| 现象 | 原因 | 解决 |
|---|---|---|
| Sideloadly 提示 "Could not connect to device" | 缺 Apple USB 驱动 | 装官网版 iTunes，重启电脑 |
| 装完点开闪退 / 提示"未受信任的开发者" | 没信任证书 | 设置 ▸ 通用 ▸ VPN与设备管理 ▸ 信任 |
| 装好后打不开，也没有任何提示 | 没开开发者模式 | 设置 ▸ 隐私与安全性 ▸ 开发者模式 → 开 → 重启 |
| 提示 "This app requires iOS 17.0 or later" | 手机系统太旧 | 升级 iPhone 到 iOS 17+ |
| 提示 bundle id 已存在 / 装不上第二个 | 免费账号只能 3 个自签 App | 删掉一个旧的，或改 `project.yml` 里的 `PRODUCT_BUNDLE_IDENTIFIER` |
| 用了 7 天突然打不开 | 免费签名过期 | 重跑 Sideloadly，或上 AltStore 自动续签 |
| Actions 跑到一半失败 | Xcode 版本或 XcodeGen 装失败 | 看日志最后 20 行，把报错发我 |
| App 没有图标（白图标） | 还没做图标资源 | 给我一张 1024×1024 的图，我生成全套 AppIcon |

---

## 七、我需要你告诉我的

1. **iPhone 系统是 iOS 17 或更高吗？**（不是的话我要把 SwiftData 换成 UserDefaults 存 JSON，降到 iOS 16）
2. **你有 iPad 吗？**（有的话可以走路线 D，不用买云 Mac 也不用侧载）
3. **是只想自己用，还是想给同事/朋友也用？**（决定要不要买 99 美元的开发者账号）

告诉我这三点，我把对应的步骤再细化到「照着敲就行」的程度。
