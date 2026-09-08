#!/usr/bin/env bash
# dotfiles 一键安装 —— 在任意 Linux 服务器上执行
# 用法:
#   bash install.sh                    # 基础安装(链接配置 + 追加 loader)
#   bash install.sh --with-starship    # 同时自动安装 starship
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 1. starship(可选) ----------
if ! command -v starship >/dev/null 2>&1; then
    if [[ "${1:-}" == "--with-starship" ]]; then
        echo "==> 安装 starship..."
        curl -sS https://starship.rs/install.sh | sh
    else
        echo "==> 未检测到 starship。可运行 'bash install.sh --with-starship' 自动安装,"
        echo "    或手动安装后重跑本脚本(不装也能用,只是提示符还是默认样式)。"
    fi
fi

# ---------- 2. starship.toml → ~/.config/starship.toml ----------
mkdir -p "$HOME/.config"
if [[ -e "$HOME/.config/starship.toml" && ! -L "$HOME/.config/starship.toml" ]]; then
    BACKUP="$HOME/.config/starship.toml.bak.$(date +%Y%m%d%H%M%S)"
    mv "$HOME/.config/starship.toml" "$BACKUP"
    echo "==> 已备份原有 starship.toml → $BACKUP"
fi
ln -sfn "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
echo "==> 已链接 ~/.config/starship.toml → $DOTFILES_DIR/config/starship.toml"

# ---------- 3. ~/.bashrc 末尾追加 loader(幂等) ----------
if grep -q "dotfiles-loader" "$HOME/.bashrc" 2>/dev/null; then
    echo "==> ~/.bashrc 已包含 dotfiles loader,跳过"
else
    {
        echo ""
        echo "# >>> dotfiles-loader >>>"
        echo "[ -f \"$DOTFILES_DIR/bashrc.d/custom.sh\" ] && . \"$DOTFILES_DIR/bashrc.d/custom.sh\""
        echo "# <<< dotfiles-loader <<<"
    } >> "$HOME/.bashrc"
    echo "==> 已在 ~/.bashrc 末尾追加 loader"
fi

# ---------- 4. agent skills(逐个软链,不覆盖本地已有) ----------
if [[ -d "$DOTFILES_DIR/skills" ]]; then
    mkdir -p "$HOME/.agents/skills"
    N=0
    for SKILL_DIR in "$DOTFILES_DIR"/skills/*/; do
        NAME=$(basename "$SKILL_DIR")
        if [[ -e "$HOME/.agents/skills/$NAME" && ! -L "$HOME/.agents/skills/$NAME" ]]; then
            echo "==> 跳过已存在的本地 skill: $NAME"
            continue
        fi
        ln -sfn "${SKILL_DIR%/}" "$HOME/.agents/skills/$NAME"
        N=$((N+1))
    done
    echo "==> 已链接 $N 个 agent skills → ~/.agents/skills/"
fi

echo ""
echo "完成!执行 'exec bash' 立即生效。"
