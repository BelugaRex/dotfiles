#!/usr/bin/env bash
# dotfiles 一键安装 —— 在 Linux / macOS / Windows Git Bash 上执行
# 用法:
#   bash install.sh                      # 完整安装(starship + 字体 + 软链配置 + shell loader + skills 同步)
#   bash install.sh --without-starship   # 跳过 starship(已装过/网络受限); --with-starship 兼容保留
#   bash install.sh --without-font       # 跳过 FiraCode Nerd Font(服务器上用不到时可省约 30MB 下载)
# 说明:
#   Windows 原生(PowerShell)没有 bash,无法运行本脚本,
#   请在原生 PowerShell 里执行 powershell/install.ps1(见 README「Windows 原生」)。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 平台探测 ----------
case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux*)               PLATFORM=linux ;;
    Darwin*)              PLATFORM=macos ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM=windows-gitbash ;;
    *)                    PLATFORM=unknown ;;
esac
echo "==> 检测到平台: $PLATFORM"

# ---------- 1. starship(默认自动装到用户级 ~/.local/bin,无需 sudo) ----------
# 说明: starship 是提示符核心, 缺失时 custom.sh 的初始化会被跳过、终端保持默认样式,
#       因此默认安装; 装用户级目录, 不动系统路径, 也不影响机器上其他用户。
SKIP_STARSHIP=false
SKIP_FONT=false
for ARG in "$@"; do
    case "$ARG" in
        --without-starship|--no-starship) SKIP_STARSHIP=true ;;
        --without-font|--no-font)         SKIP_FONT=true ;;
        --with-starship) ;;   # 兼容旧写法: 现在本来就是默认行为
        *) echo "警告: 未识别的参数 '$ARG'(仅支持 --without-starship / --without-font)" >&2 ;;
    esac
done

install_starship() {
    mkdir -p "$HOME/.local/bin"
    case "$PLATFORM" in
        macos)
            # 有 brew 优先走 brew;否则用官方脚本装到用户级目录
            if command -v brew >/dev/null 2>&1; then
                brew install starship
            else
                curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
            fi
            ;;
        *)
            # Linux / Windows Git Bash 均适用官方脚本(固定用户级目录, 避免 sudo)
            curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
            ;;
    esac
}

if $SKIP_STARSHIP; then
    echo "==> 已按参数跳过 starship 安装(提示符将保持默认样式)。"
elif command -v starship >/dev/null 2>&1; then
    echo "==> 已检测到 starship: $(starship --version 2>/dev/null | head -1)"
elif install_starship; then
    export PATH="$HOME/.local/bin:$PATH"   # 让当前会话立即生效(新终端由 custom.sh 负责)
    if command -v starship >/dev/null 2>&1; then
        echo "==> starship 安装完成: $(starship --version 2>/dev/null | head -1)"
    else
        echo "==> starship 已装到 ~/.local/bin(重开终端后生效)"
    fi
else
    echo "==> starship 自动安装失败(网络受限?)"
    echo "    联网后重跑 'bash install.sh' 即可(各步骤幂等); 手动安装见 README「从零恢复」."
fi

# ---------- 2. FiraCode Nerd Font(用户级安装) ----------
# 提示符由客户端终端渲染, 服务器上装字体无害但无用(纯文本主题也不强依赖字体);
# 全新客户端上这一步才真正生效。安装细节与幂等判断见 fonts/install-font.sh。
if $SKIP_FONT; then
    echo "==> 已按参数跳过字体安装。"
elif [[ "$PLATFORM" == windows-gitbash ]]; then
    echo "==> Windows 客户端: 请在原生 PowerShell 里执行 powershell/install.ps1(含字体安装)。"
elif bash "$DOTFILES_DIR/fonts/install-font.sh"; then
    : # 安装/跳过信息由 install-font.sh 自行输出
else
    echo "==> 字体自动安装失败(网络受限?)。"
    echo "    稍后单独重跑 'bash fonts/install-font.sh' 即可, 不影响其余配置。"
fi

# ---------- 3. starship.toml → ~/.config/starship.toml ----------
mkdir -p "$HOME/.config"
CONFIG_TARGET="$HOME/.config/starship.toml"
if [[ -e "$CONFIG_TARGET" && ! -L "$CONFIG_TARGET" ]]; then
    BACKUP="$HOME/.config/starship.toml.bak.$(date +%Y%m%d%H%M%S)"
    mv "$CONFIG_TARGET" "$BACKUP"
    echo "==> 已备份原有 starship.toml → $BACKUP"
fi
if ln -sfn "$DOTFILES_DIR/config/starship.toml" "$CONFIG_TARGET" 2>/dev/null; then
    echo "==> 已链接 ~/.config/starship.toml → $DOTFILES_DIR/config/starship.toml"
else
    # 少数平台(如挂载选项禁用符号链接)创建软链失败时退化为复制
    cp -a "$DOTFILES_DIR/config/starship.toml" "$CONFIG_TARGET"
    echo "==> 软链失败,已改为复制到 ~/.config/starship.toml"
    echo "    (以后仓库更新需重跑本脚本覆盖,或改为手动 git pull 后复制)"
fi

# ---------- 4. shell loader(幂等,写入前自动备份) ----------
LOADER_SNIPPET="[ -f \"$DOTFILES_DIR/bashrc.d/custom.sh\" ] && . \"$DOTFILES_DIR/bashrc.d/custom.sh\""
append_loader() {
    local RC="$1"
    if grep -q "dotfiles-loader" "$RC" 2>/dev/null; then
        echo "==> $RC 已包含 dotfiles loader,跳过"
        return
    fi
    if [[ -f "$RC" ]]; then
        local BACKUP_RC="$RC.bak.$(date +%Y%m%d%H%M%S)"
        cp -a "$RC" "$BACKUP_RC"
        echo "==> 已备份 $RC → $BACKUP_RC"
    fi
    {
        echo ""
        echo "# >>> dotfiles-loader >>>"
        echo "$LOADER_SNIPPET"
        echo "# <<< dotfiles-loader <<<"
    } >> "$RC"
    echo "==> 已向 $RC 追加 loader"
}

# bash:~/.bashrc(Linux / WSL / Git Bash;macOS 上用 bash 的用户)
append_loader "$HOME/.bashrc"

if command -v zsh >/dev/null 2>&1; then
    append_loader "$HOME/.zshrc"
fi

# ---------- 5. agent skills(复制为真实目录,兼容不跟随软链的工具,如 Copilot MCP 扩展) ----------
if [[ -d "$DOTFILES_DIR/skills" ]]; then
    mkdir -p "$HOME/.agents/skills"
    # 清理旧版软链方式的链接项(只删软链,不动真实目录)
    for ITEM in "$HOME"/.agents/skills/*; do
        [[ -L "$ITEM" ]] && rm -f "$ITEM"
    done
    N=0
    for SKILL_DIR in "$DOTFILES_DIR"/skills/*/; do
        NAME=$(basename "$SKILL_DIR")
        rm -rf "$HOME/.agents/skills/$NAME"
        cp -a "${SKILL_DIR%/}" "$HOME/.agents/skills/$NAME"
        N=$((N+1))
    done
    echo "==> 已同步 $N 个 agent skills → ~/.agents/skills/ (真实目录)"
fi

echo ""
echo "完成! 提示符由 starship 渲染(ohmyzsh ys 风格), 配置经本仓库软链生效。"
case "$PLATFORM" in
    macos)
        echo "  执行 'exec zsh' 立即生效(或重开终端)。"
        ;;
    *)
        echo "  执行 'exec bash' 立即生效(或重开终端)。"
        ;;
esac
