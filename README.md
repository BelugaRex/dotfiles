# dotfiles

个人 bash/zsh 环境配置，方便在 **Linux / macOS / Windows（Git Bash 或原生 PowerShell）** 之间保持一致风格。

构成：**Starship 提示符（ohmyzsh ys 风格）+ 通用 bash 自定义 + 一键安装脚本 + 字体安装脚本**。

效果：

```
# user @ host in ~/code [21:47:42]
$ ls
```

## 从零恢复（双端全新机器）

目标是：服务器和客户端**都是空白机器**时，各跑一条命令即可恢复。SSH 密钥、token 等凭据**不在本仓库覆盖范围内**，需单独恢复。

客户端是哪种系统都覆盖，三端路径一览（服务器永远只跑 `install.sh`）：

| 客户端系统 | 客户端本地恢复命令 | 装完还差的一步（终端里选字体） |
|---|---|---|
| Linux（含 WSL） | `bash install.sh`（字体/提示符全自动） | GNOME Terminal: 首选项→配置文件→文本→自定义字体；VS Code 见下 |
| macOS | `bash install.sh`（自动写 `~/.zshrc`） | Terminal.app / iTerm2 / VS Code 选字体，见「字体美化」 |
| Windows 原生 | `powershell -ExecutionPolicy Bypass -File .\powershell\install.ps1` | Windows Terminal: 设置→默认值→外观→字体；VS Code 见下 |

**Linux / WSL / macOS / Windows Git Bash**（有 bash 即可）：

```bash
git clone https://github.com/BelugaRex/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && bash install.sh
exec bash        # macOS 默认 zsh 的用户执行 exec zsh
```

**没有 git 的空白机器**（curl 兜底，任何有 bash 的机器都行）：

```bash
curl -sSL https://github.com/BelugaRex/dotfiles/archive/refs/heads/main.tar.gz | tar xz
cd dotfiles-main && bash install.sh && exec bash   # macOS: exec zsh
```

`install.sh` 会自动探测平台（幂等，可重复执行）：

1. **默认安装 starship** 到用户级 `~/.local/bin`（无需 sudo；macOS 有 brew 走 `brew install`，否则官方脚本；已装则跳过，加 `--without-starship` 可显式跳过）
2. **默认安装 FiraCode Nerd Font** 到用户级字体目录（幂等；服务器上无害但用不到，可加 `--without-font` 省一次约 30MB 下载；Windows Git Bash 会提示改用 install.ps1）
3. 把本仓库的 `starship.toml` 软链到 `~/.config/`（原有文件自动备份；软链失败时退化为复制）
4. 追加 loader 到 `~/.bashrc`；只要机器上装了 zsh 也一并追加到 `~/.zshrc`（改写前自动备份，不动原内容）——日后切 zsh 立即生效

**macOS 用户**：与上面完全同一套流程，无需额外步骤——脚本自动探测 Darwin、默认安装 starship（有 brew 走 `brew install starship`，否则官方脚本装到 `~/.local/bin`）、loader 自动写入 `~/.zshrc`、字体自动装到用户目录，提示符即由 starship 渲染。

**Windows 原生 PowerShell**（客户端是 Windows 时的原生方案）：

```powershell
git clone https://github.com/BelugaRex/dotfiles.git $HOME\.dotfiles
cd $HOME\.dotfiles
powershell -ExecutionPolicy Bypass -File .\powershell\install.ps1
# 没有 git 时: Invoke-WebRequest https://github.com/BelugaRex/dotfiles/archive/refs/heads/main.zip -OutFile dotfiles.zip; Expand-Archive dotfiles.zip -DestinationPath .; cd dotfiles-main
```

`install.ps1` 自动完成：winget 装 starship → 把 FiraCode Nerd Font 的 4 个 ttf 装到用户级字体目录并写 HKCU 注册表（无需管理员）→ 复制 `starship.toml` → 向 `$PROFILE`（CurrentUserAllHosts，VS Code 终端也生效）写入 loader。幂等可重跑。PowerShell 5.1 与 pwsh 7 的 profile 相互独立，两个宿主都想要就各跑一次。装完新开 PowerShell，终端字体选 `FiraCode Nerd Font`。

## rtk（Token-Optimized CLI）

`rtk` 是 x86-64 静态链接二进制，可直接从已有机器拷贝：

```bash
scp any-machine:~/.local/bin/rtk ~/.local/bin/rtk
```

或在目标服务器上按官方方式重装。

## 字体美化（本地终端，服务器无需安装）

提示符由**本地终端**渲染，字体是客户端配置，服务器上不用装任何字体。

当前环境的字体方案：

- **VS Code 集成终端**：FiraCode Nerd Font（`"terminal.integrated.fontFamily": "'FiraCode Nerd Font'"`）
- **Windows Terminal**：未单独配置，使用默认 Cascadia Mono

本主题刻意只用纯文本符号 + emoji，不依赖 Nerd Font 图标——没装字体也能完整显示，装了则额外获得连字（ligatures）与图标字形能力。

**一键安装（Linux / macOS，用户级、无需 sudo、幂等）**（`install.sh` 已默认自动执行，此命令用于补装/重装）：

```bash
bash fonts/install-font.sh
```

- Linux：解压到 `~/.local/share/fonts/FiraCode` 并刷新 fontconfig 缓存
- macOS：有 brew 走 `brew install --cask font-fira-code-nerd-font`，否则解压到 `~/Library/Fonts`
- Windows（Git Bash 内）/ 手动步骤见下文

**Windows（WSL 上层）安装 FiraCode Nerd Font：**

1. 从 [nerd-fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/latest) 下载 `FiraCode.zip`
2. 解压后全选 ttf 文件 → 右键「安装」
3. VS Code 设置加：`"terminal.integrated.fontFamily": "'FiraCode Nerd Font'"`
4. （可选）Windows Terminal → 设置 → 默认值 → 外观 → 字体 → `FiraCode Nerd Font`

**macOS 安装 FiraCode Nerd Font：**

```bash
brew install --cask font-fira-code-nerd-font
```

（没装 brew 的话：从 [nerd-fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/latest) 下载 `FiraCode.zip`，解压后把 ttf 拖进「字体册.app」，或拷到 `~/Library/Fonts/`）

装完在 macOS 客户端配置：

- **VS Code**：设置 `"terminal.integrated.fontFamily": "'FiraCode Nerd Font'"`
- **系统 Terminal.app**：终端 → 设置 → 描述文件 → 文本 → 字体 → `FiraCode Nerd Font`
- **iTerm2**：Settings → Profiles → Text → Font → `FiraCode Nerd Font`

**Linux 本机/桌面（可选）：**

```bash
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
unzip -o FiraCode.zip -d FiraCode && rm FiraCode.zip && fc-cache -f
```

装完在 Linux 客户端配置字体：

- **GNOME Terminal**：首选项 → 配置文件 → 文本 → 自定义字体 → `FiraCode Nerd Font`
- **Konsole**：设置 → 编辑当前配置文件 → 外观 → 字体 → `FiraCode Nerd Font`

## 脱敏要求（分享 / AI 会话前必做）

凡是把终端输出、日志、配置**发给别人或 AI 助手看**（截图、粘贴、对话引用），必须先脱敏：

- 主机名、用户名、IP、内部域名 → 替换为 `host`、`user`、`x.x.x.x` 等占位符
- token、密钥、密码、cookie、私钥 → 一律替换为 `***`，不要展示任何真实片段
- 内部路径、项目代号 → 泛化为 `~/project` 之类的通用形式

```
# 原始
# user @ my-real-host in ~/code [13:42:02]
# 脱敏后
# user @ host in ~/code [13:42:02]
```

AI 编码助手（Copilot 等）在本机工作时引用的输出同样适用本要求。

## Agent Skills（AI 编程助手技能包）

`skills/` 保存当前使用的 **12 个入口**，以本机 `~/.agents/skills/` 的审定版本为发布快照（2026-11-17）。PUA 和 Caveman 已整合为单入口，通常用自然语言选择模式，不再安装一批独立别名。

| 入口 | 说明 |
|---|---|
| `pua` | 查证与生产率方法；统一 P7/P9/P10、pro/KPI、mama/yes/ding、shot、有限次迭代及中英日输出 |
| `caveman` | 简洁输出及文言强度；按任务选择提交信息、代码审查、指定文档压缩和统计说明 |
| `planning-with-files` | 三文件持久规划；上游快照 **3.28.2**，Copilot 适配 **copilot.1** |
| `answer-framework` | 结构化、基于证据的问答 |
| `cavecrew` | 只读分析与有界实现子代理的协作约定 |
| `double-check` | 修改后连续两次验证与提交约定 |
| `karpathy-guidelines` | 最小改动、明确假设与可验证目标 |
| `i-have-adhd` | 手动启用的 ADHD 友好呈现，不截断实际分析范围 |
| `improve-codebase-architecture` | 手动启用的架构分析与报告；缺少外部技能时使用本地参考 |
| `always-ask-next` | 完成后提供三个相关后续选项和自由输入 |
| `refactoring-fowler` | 按 Fowler 方法识别代码异味、小步重构并保持行为 |
| `agi-gallery` | 保留既有版本，本次同步不更新 |

这是 **Copilot 技能文本与辅助文件**，不是宿主插件：安装不注册生命周期 hooks、后台循环、自动上下文注入或确定性停止门禁；技能自动选择依赖宿主，新会话才会重新发现元数据。`cavecrew` 所需的两个自定义代理模板不在本仓库安装范围内，须另行配置；没有相应能力时不能假装已执行。技能内保留的其他宿主脚本/示例不代表已经启用。

`install.sh` 会把它们**复制**为真实目录到 `~/.agents/skills/`（同名技能以仓库为准，重跑即覆盖更新）。不用软链是因为部分工具用 `readdir` 判断目录类型，不跟随软链。**安装前请备份同名技能的本地修改**。仓库外的目录、有效软链及悬空软链均不改动；原生 PowerShell 安装器目前只安装终端环境，不同步技能。

### 从旧版 49 入口升级

本轮新增 `always-ask-next`、`refactoring-fowler`，并从仓库退役以下 **39 个旧入口**；旧版本仍在 Git 历史中。已有机器上的旧目录/链接**不会自动删除**，确认没有个人修改并自行备份后，再按下列清单处理，避免误删其他来源的同名技能：

- Caveman：`caveman-commit`、`caveman-compress`、`caveman-help`、`caveman-review`、`caveman-stats`。
- PUA 别名：`pua-cancel-loop`、`pua-en`、`pua-flavor`、`pua-ja`、`pua-kpi`、`pua-loop`、`pua-mama`、`pua-off`、`pua-offline`、`pua-on`、`pua-p10`、`pua-p7`、`pua-p9`、`pua-pro`、`pua-reap-orphans`、`pua-survey`、`pua-team-status`、`pua-teardown-all`、`pua-trae`、`pua-yes`。
- 角色/风格：`ding`、`mama`、`p7`、`p9`、`p10`、`pro`、`shot`、`yes`。
- 重复规划入口：`pi-planning-with-files`、`planning-with-files-ar`、`planning-with-files-de`、`planning-with-files-es`、`planning-with-files-zh`、`planning-with-files-zht`。多语言需求直接向当前技能说明即可。

各技能的许可证和来源保留在对应目录；`LOCAL-PATCH.md` 说明本地适配与限制。PUA 上游快照未附 LICENSE 文件，保留该事实说明，不据此推定新的授权。私有维护快照、回滚记录、真实会话和个人资源不随仓库发布。

### 验证

运行 `python3 -I -B tests/verify_skills.py`（Python 3.11+，仅标准库）。测试检查技能入口、引用、脚本语法、脱敏约束，并用合成技能及临时 HOME 验证安装覆盖、幂等性和第三方技能保护；辅助脚本使用临时用例。测试不安装程序/字体，不读取 `agi-gallery` 正文、真实会话或凭据，不改当前 HOME。Linux 测试通过不等于 macOS/Windows 实机或新会话自动发现已经验证。

## 目录结构

```
dotfiles/
├── install.sh             # 一键安装脚本(自动探测 Linux/macOS/Git Bash)
├── bashrc.d/custom.sh     # bash/zsh 通用自定义(PATH/历史/别名/starship/nvm)
├── powershell/install.ps1 # Windows 原生一键安装(starship + 字体 + profile loader)
├── powershell/profile.ps1 # Windows 原生 PowerShell profile(由 install.ps1 写入 loader)
├── config/starship.toml   # starship 主题(ohmyzsh ys 复刻,去 VCS 模块)
├── fonts/install-font.sh  # FiraCode Nerd Font 一键安装(用户级,Linux/macOS)
├── tests/verify_skills.py # 标准库隔离验证(不修改真实 HOME)
└── skills/                # 12 个技能入口(单入口整合的 Copilot 适配快照)
```
