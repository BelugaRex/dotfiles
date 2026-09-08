# dotfiles

个人 bash 环境配置，方便在不同 Linux 服务器间保持一致的风格。

构成：**Starship 提示符（ohmyzsh ys 风格）+ 通用 bash 自定义 + 一键安装脚本**。

效果：

```
# user @ host in ~/code [21:47:42]
$ ls
```

## 在新服务器上使用

```bash
git clone https://github.com/BelugaRex/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && bash install.sh
exec bash
```

`install.sh` 做三件事（幂等，可重复执行）：

1. 可选安装 starship（加 `--with-starship` 参数自动装）
2. 把本仓库的 `starship.toml` 软链接到 `~/.config/`（原有文件自动备份）
3. 在 `~/.bashrc` 末尾追加 loader，加载 `bashrc.d/custom.sh`（不动发行版自带的 bashrc）

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

`install.sh` 会把它们逐个软链接到 `~/.agents/skills/`——**只链接、不覆盖**：目标机器上已存在的同名本地 skill 会被跳过。

不同 agent 运行时的技能目录可能不同（如 `~/.claude/skills`），需要时仿照 install.sh 里的循环再加一条软链即可。

## 目录结构

```
dotfiles/
├── install.sh           # 一键安装脚本
├── bashrc.d/custom.sh   # bash 自定义段落（PATH/历史/别名/starship/nvm）
├── config/starship.toml # starship 主题（ohmyzsh ys 复刻，去 VCS 模块）
└── skills/              # 49 个 agent skills（pua / caveman / planning 等）
```
