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

## 目录结构

```
dotfiles/
├── install.sh           # 一键安装脚本
├── bashrc.d/custom.sh   # bash 自定义段落（PATH/历史/别名/starship/nvm）
└── config/starship.toml # starship 主题（ohmyzsh ys 复刻，去 VCS 模块）
```
