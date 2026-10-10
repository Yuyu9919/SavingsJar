# 两台电脑之间怎么衔接（工作电脑 ⇄ 家里电脑）

> **一句话原则：GitHub 是唯一的真相源，本地电脑只是编辑器。**
>
> 只要代码在 GitHub 上，你在哪台电脑上干活都行 —— 而且因为构建是在云端跑的，
> **两台电脑都不需要有 Mac。**

---

## 一、先想清楚：什么会同步，什么不会

| 内容 | 会不会自动同步 | 说明 |
|---|---|---|
| **代码、文档、配置** | ✅ 会 | 通过 git，这是主体 |
| **云端构建 / TestFlight** | ✅ 会 | 在 GitHub 服务器上跑，和设备无关 |
| **AI 的对话记忆** | ❌ 不会 | 换电脑 = 新的会话上下文。**已用 `DEVLOG.md` 解决**（见第四节） |
| **本地的 git 身份配置** | ❌ 不会 | 每台电脑要各配一次 |
| **证书、私钥（.p12/.p8）** | ❌ 不会，**也不该** | 已被 `.gitignore` 排除。要用时单独传 |
| **Sideloadly / iTunes 等软件** | ❌ 不会 | 每台电脑各装一次 |

---

## 二、今晚离开工作电脑前，做这三件事（约 20 分钟）

### 2.1 ⚠️ 先检查邮箱 —— 这一步关系到隐私，别跳过

如果把仓库建成 **Public**，那么**每一个 commit 里都会公开记录作者邮箱**，
任何人都能用 GitHub 搜索看到。**绝对不要用公司邮箱。**

改用 GitHub 提供的匿名邮箱：

1. 打开 <https://github.com/settings/emails>
2. 勾上 **Keep my email addresses private**
3. 页面会显示你的专属 noreply 邮箱，形如：
   `12345678+你的用户名@users.noreply.github.com`
4. 用这个邮箱配置 git：

```bash
git config --global user.name "你的名字或昵称"
git config --global user.email "12345678+你的用户名@users.noreply.github.com"
```

> 这样提交记录里显示的是 `@users.noreply.github.com` 邮箱，
> 既不影响 GitHub 把你的 commit 算到你头上，也不会泄露真实邮箱和公司信息。

### 2.2 推送代码

```bash
# 在项目根目录（SavingsJar/）执行
git add .
git commit -m "feat: 攒钱罐 v0.1 首次提交"
git remote add origin https://github.com/<你的用户名>/SavingsJar.git
git push -u origin main
```

### 2.3 确认能推上去

如果公司网络或电脑管控拦住了，会在这一步暴露（见第五节的处理办法）。

---

## 三、家里电脑上的第一次设置（约 15 分钟）

### 3.1 装 Git

下载 <https://git-scm.com/download/win>，一路默认安装即可。

### 3.2 配置身份（和上面一样的邮箱）

```bash
git config --global user.name "你的名字或昵称"
git config --global user.email "12345678+你的用户名@users.noreply.github.com"
```

### 3.3 克隆项目

选一个你喜欢的目录，比如 `D:\Projects`：

```bash
cd /d/Projects
git clone https://github.com/<你的用户名>/SavingsJar.git
cd SavingsJar
```

### 3.4 用 WorkBuddy 打开这个目录

把 `D:\Projects\SavingsJar`（或你选的路径）作为工作区打开。
然后让 AI **先读 `DEVLOG.md`** —— 那里有全部上下文，读完就能无缝接上。

### 3.5 要侧载的话，再装这两个

- **Sideloadly**：<https://sideloadly.io>
- **iTunes 官网版**：<https://www.apple.com/itunes/>（⚠️ 别用 Microsoft Store 版）

### 3.6 要重新生成图标的话，装 Python + Pillow

```bash
python -m pip install Pillow
python tools/make_icon.py
```

---

## 四、AI 记忆怎么带过去（这是最容易出问题的地方）

AI 助手的工作区记忆是**存在本地工作区里**的，换电脑就没了。
所以我把关键上下文固化进了仓库里的 **`DEVLOG.md`**：

| 里面写了什么 | 为什么重要 |
|---|---|
| 项目是什么、当前阶段 | 新会话不用从头解释 |
| 开发者的环境约束（Windows / 无 Mac / 有 iPhone） | 避免 AI 让你去按 ⌘R |
| **6 条关键技术决策**（SwiftData 的 `id` 冲突、key path 不能指元组…） | 避免重复踩坑 |
| 文件地图、设计令牌、五种储蓄节奏 | 快速定位 |
| 当前进度与待办 | 知道下一步做什么 |
| 进度日志 | 时间线 |

### 使用约定

**每次收工前，在 `DEVLOG.md` 的「进度日志」表格里追加一行。** 例如：

```markdown
| 2026-10-11 | 推通了云构建，修了 3 个编译错误。侧载成功，开始测 A 组。 |
```

一行就够。这样换电脑、隔几周再回来、或者开新会话，都不会断片。

### 在任意一台电脑上开新会话时的开场白

> 「读一下 `DEVLOG.md`，然后我们继续。」

---

## 五、工作电脑上的三个风险（提前知道）

### 5.1 企业管控可能拦住 git push

公司电脑常有 DLP（数据防泄漏）、代理或网络白名单，可能表现为：

- `git push` 卡住不动 / 连接超时
- 提示证书错误（`SSL certificate problem`）
- 直接提示被策略阻止

**先试着推一次**，如果被拦住，有两条退路：

1. **改用 GitHub 网页上传**：适合改少量文件（网页上 Edit 单个文件提交）
2. **工作电脑只做"看"，不做"改"**：把开发集中在家里电脑，白天用手机看看进度

### 5.2 装不了个人软件

Sideloadly、iTunes 这类软件在工作电脑上通常装不了（需要管理员权限，也可能不合规）。

**建议分工：**

| 在哪台电脑 | 做什么 |
|---|---|
| 工作电脑 | 写代码、改文档、`git push`（轻量操作） |
| **家里电脑** | **云构建触发、下载 IPA、Sideloadly 侧载、真机测试**（重活） |

### 5.3 别把工作资料混进这个仓库

这个仓库会推到 GitHub。**不要**把任何工作相关的文件（客户资料、公司文档、内部数据）放进 `SavingsJar` 目录。

顺带一提：`.gitignore` 里已经排除了所有证书和私钥文件（`*.p12` / `*.p8` / `*.mobileprovision`），
这类东西**永远不要**提交到 git，哪怕是私有仓库。

---

## 六、日常切换的标准动作

### 离开任何一台电脑前

```bash
git add .
git commit -m "wip: <一句话说明改了什么>"
git push
```

### 在另一台电脑开始前

```bash
git pull
```

**就这两条命令。** 养成"离开前 push、开始前 pull"的习惯，两台电脑永远不会冲突。

### 如果忘记 push 就换了电脑

没关系的 —— 那部分改动还在原来那台电脑上。回去补一次 push 即可。
**唯一会出问题的情况是：两台电脑同时改了同一批文件**。所以尽量别并行改。

---

## 七、可选的进阶做法

### 7.1 用分支做实验

如果想在某台电脑上试一个大改动、又不想影响另一台：

```bash
git checkout -b experiment-ui    # 建分支
# ...改代码...
git push -u origin experiment-ui # 推分支
```

云端构建会自动为分支跑一次，可以对照着比较效果。

### 7.2 两台电脑都想用 AI 帮忙

两台都装 WorkBuddy 就行。因为是同一个 git 仓库，AI 在两边看到的代码是一样的。
只要记得：**每次开新会话，先让 AI 读 `DEVLOG.md`。**

### 7.3 想看某次改动到底改了什么

```bash
git log --oneline -10      # 最近 10 次提交
git show <提交ID>          # 看某次具体改了什么
git diff                   # 看当前还没提交的改动
```

---

## 八、交接检查清单

### 离开工作电脑前
- [ ] 邮箱已换成 GitHub 的 noreply 邮箱（不是公司邮箱）
- [ ] `git add . && git commit -m "..." && git push` 成功
- [ ] `DEVLOG.md` 的进度日志追加了今天做的事
- [ ] 确认没有工作相关的文件混进 SavingsJar 目录

### 到家后
- [ ] `git pull` 拉到最新
- [ ] 让 AI 先读 `DEVLOG.md`
- [ ] 继续上次的待办

---

## 九、一图流总结

```
   工作电脑                          家里电脑
  ┌──────────┐                    ┌──────────┐
  │ 写代码    │                    │ 写代码    │
  │ 改文档    │                    │ 跑构建    │
  │ git push │                    │ 下载 IPA  │
  └────┬─────┘                    │ Sideloadly│
       │                          │ 真机测试  │
       │      ┌───────────┐       └─────┬────┘
       └─────▶│  GitHub   │◀────────────┘
              │           │
              │ · 代码仓库 │   ← 唯一的真相源
              │ · 云构建   │   ← 不需要 Mac
              │ · Actions │
              └───────────┘
                    │
                    ▼
              App Store Connect
              （TestFlight / 上架）
```

**核心：代码放 GitHub，构建放云端，两台电脑都只当编辑器用。**
