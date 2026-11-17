#!/usr/bin/env bash
# dotfiles 一键安装 —— 在 Linux / macOS / Windows Git Bash 上执行
# 用法:
#   bash install.sh                      # 完整安装(starship + 字体 + 软链配置 + shell loader + skills 同步)
#   bash install.sh --help               # 查看全部选项(不修改任何文件)
#   bash install.sh --without-starship   # 跳过 starship(已装过/网络受限); --with-starship 兼容保留
#   bash install.sh --without-font       # 跳过 FiraCode Nerd Font(服务器上用不到时可省约 30MB 下载)
#   bash install.sh --with-font          # 远程/无图形会话下也强制安装字体
# 说明:
#   Windows 原生(PowerShell)没有 bash,无法运行本脚本,
#   请在原生 PowerShell 里执行 powershell/install.ps1(见 README「Windows 原生」)。
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'EOF'
用法: bash install.sh [选项]

选项:
  -h, --help           显示本帮助后退出(不修改任何文件)
  --without-starship   跳过 starship 安装(已装过/网络受限)
  --with-starship      兼容旧写法(starship 本来就是默认安装)
  --without-font       跳过 FiraCode Nerd Font 安装
  --with-font          远程或无图形会话下也强制安装字体

字体在 SSH / 无图形会话下默认跳过: 提示符由客户端终端渲染,
服务器上装了也用不到。需要时单独跑 bash fonts/install-font.sh。
EOF
}

# ---------- 参数解析(先于任何副作用, 保证 --help 不改动系统) ----------
SKIP_STARSHIP=false
SKIP_FONT=false
FORCE_FONT=false
for ARG in "$@"; do
    case "$ARG" in
        -h|--help)                        usage; exit 0 ;;
        --without-starship|--no-starship) SKIP_STARSHIP=true ;;
        --without-font|--no-font)         SKIP_FONT=true ;;
        --with-font)                      FORCE_FONT=true ;;
        --with-starship) ;;   # 兼容旧写法: 现在本来就是默认行为
        *) echo "警告: 未识别的参数 '$ARG'(用 --help 查看支持的选项)" >&2 ;;
    esac
done

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
elif [[ -x "$HOME/.local/bin/starship" ]]; then
    # 重跑场景: 二进制已在但当前会话 PATH 还没带上 ~/.local/bin, 不重复下载
    echo "==> 已检测到 starship: $("$HOME/.local/bin/starship" --version 2>/dev/null | head -1)"
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
# 远程 / 无图形会话默认跳过, 避免白下载约 30MB; 需要时用 --with-font 强制。
HEADLESS=false
if [ -n "${SSH_CONNECTION-}${SSH_CLIENT-}${SSH_TTY-}" ] \
    || { [ -z "${DISPLAY-}" ] && [ -z "${WAYLAND_DISPLAY-}" ]; }; then
    HEADLESS=true
fi

if $SKIP_FONT; then
    echo "==> 已按参数跳过字体安装。"
elif [[ "$PLATFORM" == windows-gitbash ]]; then
    echo "==> Windows 客户端: 请在原生 PowerShell 里执行 powershell/install.ps1(含字体安装)。"
elif $HEADLESS && ! $FORCE_FONT; then
    echo "==> 未检测到图形会话(远程/无显示), 跳过字体下载。"
    echo "    提示符由客户端终端渲染; 确实要装在这台机器上: bash fonts/install-font.sh"
    echo "    或 bash install.sh --with-font"
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
    # 只替换仓库内同名项(含旧软链),保留其他工具安装的目录和链接。
    # 覆盖前把有本地差异的旧版本备份到 ~/.agents/skills-backup/<时间戳>/, 便于找回个人修改。
    BACKUP_ROOT="$HOME/.agents/skills-backup/$(date +%Y%m%d%H%M%S)"
    N=0
    BACKED_UP=0
    for SKILL_DIR in "$DOTFILES_DIR"/skills/*/; do
        NAME=$(basename "$SKILL_DIR")
        TARGET="$HOME/.agents/skills/$NAME"
        if [ -e "$TARGET" ] && ! diff -rq "${SKILL_DIR%/}" "$TARGET" >/dev/null 2>&1; then
            mkdir -p "$BACKUP_ROOT"
            cp -a "$TARGET" "$BACKUP_ROOT/$NAME"
            BACKED_UP=$((BACKED_UP+1))
        fi
        rm -rf "$TARGET"
        cp -a "${SKILL_DIR%/}" "$TARGET"
        N=$((N+1))
    done
    echo "==> 已同步 $N 个 agent skills → ~/.agents/skills/ (真实目录)"
    if [ "$BACKED_UP" -gt 0 ]; then
        echo "==> 覆盖前已备份 $BACKED_UP 个有本地差异的技能 → $BACKUP_ROOT"
    fi
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
