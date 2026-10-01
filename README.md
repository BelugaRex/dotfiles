# dotfiles

个人 bash/zsh 环境配置，方便在 **Linux / macOS / Windows（Git Bash 或原生 PowerShell）** 之间保持一致风格。

构成：**Starship 提示符（ohmyzsh ys 风格）+ 通用 bash 自定义 + 一键安装脚本**。

效果：

```
# user @ host in ~/code [21:47:42]
$ ls
```

## 在新机器上使用（Linux / macOS / Windows）

**Linux / WSL / macOS / Windows Git Bash**（有 bash 即可）：

```bash
git clone https://github.com/BelugaRex/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && bash install.sh
exec bash        # macOS 默认 zsh 的用户执行 exec zsh
```

`install.sh` 会自动探测平台（幂等，可重复执行）：

1. 可选安装 starship（加 `--with-starship` 参数；macOS 有 brew 走 `brew install`，否则官方脚本）
2. 把本仓库的 `starship.toml` 软链到 `~/.config/`（原有文件自动备份；软链失败时退化为复制）
3. 追加 loader 到 `~/.bashrc`；若装了 zsh、`$SHELL` 指向 zsh，或是 macOS（默认 shell 即 zsh），也一并追加到 `~/.zshrc`（改写前自动备份，不动原内容）

**macOS 用户**：与上面完全同一套流程，无需额外步骤——脚本自动探测 Darwin、`--with-starship` 走 `brew install starship`、loader 自动写入 `~/.zshrc`，提示符即由 starship 渲染；字体见下方「字体美化」一节（`brew install --cask font-fira-code-nerd-font`）。

**Windows 原生 PowerShell**（无 bash，本仓库脚本不覆盖此场景，手动三步）：

```powershell
winget install Starship.Starship            # 安装 starship
echo $PROFILE                                # 查看 profile 文件路径
# 1. 把仓库 powershell/profile.ps1 的内容追加进上面的文件(可先备份)
# 2. 把仓库 config/starship.toml 复制到 $HOME\.config\starship.toml(~/.config 需自建)
# 3. 重开 PowerShell
```

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

`skills/` 内是本人使用的 agent skills，共 **49 个**，归属 4 个技能家族 + 一批独立技能：

| 家族 | 数量 | 说明 |
|---|---|---|
| `caveman` 系列 | 6 | 超压缩沟通模式（省 token），含 commit 生成、review、统计等子命令 |
| `pua` 系列 | 21 | 生产率教练模式；多语言版（en/ja）+ 子命令别名（kpi / loop / on / off / pro / team-status 等） |
| `planning-with-files` 系列 | 7 | Manus 式文件规划（task_plan / findings / progress），含 ar / de / es / zh / zht 翻译版 |
| 职级模式 `p7` `p9` `p10` | 3 | P7 方案执行 / P9 Tech Lead 任务拆解 / P10 CTO 战略规划 |
| 独立技能 | 12 | 见下 |

独立技能：`answer-framework`（问答框架）、`cavecrew`（子代理协作）、`double-check`（改动双重校验）、`karpathy-guidelines`（编码守则）、`ding`（钉内/钉外职场提醒）、`mama`（妈妈唠叨模式）、`yes`（夸夸模式）、`shot`（PUA 速查注入）、`pro`（PUA Pro 扩展）、`i-have-adhd`（ADHD 友好输出）、`improve-codebase-architecture`（架构扫描报告）、`agi-gallery`

`install.sh` 会把它们**复制**为真实目录到 `~/.agents/skills/`（仓库为唯一来源，重跑即覆盖更新）。不用软链是因为部分工具（如 VS Code 的 Copilot MCP + Agent Skills Manager 扩展）用 `readdir` 判断目录类型，不跟随软链，会导致技能列表显示为空。

每次更新仓库后重跑 `install.sh` 即可同步；通过其他工具（如该扩展的 skills.sh 搜索）安装到 `~/.agents/skills/` 的技能不会被脚本动到（除非与仓库内技能同名，以仓库为准）。

## 目录结构

```
dotfiles/
├── install.sh             # 一键安装脚本(自动探测 Linux/macOS/Git Bash)
├── bashrc.d/custom.sh     # bash/zsh 通用自定义(PATH/历史/别名/starship/nvm)
├── powershell/profile.ps1 # Windows 原生 PowerShell profile
├── config/starship.toml   # starship 主题(ohmyzsh ys 复刻,去 VCS 模块)
└── skills/                # 49 个 agent skills(pua / caveman / planning 等)
```
