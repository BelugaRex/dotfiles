#!/usr/bin/env bash
# FiraCode Nerd Font 一键安装 —— 用户级、不需要 sudo、幂等可重跑
#
# 用法:
#   bash fonts/install-font.sh
#
# 平台:
#   Linux  → 解压到 ~/.local/share/fonts/FiraCode, 刷新 fontconfig 缓存
#   macOS  → 有 brew 走 'brew install --cask font-fira-code-nerd-font';
#             否则把 ttf 平铺进 ~/Library/Fonts
#   Windows → 不适用, 在原生 PowerShell 里执行 powershell/install.ps1
#
# 重要: 远端 SSH / VS Code Remote 场景下, 提示符由【客户端】终端渲染,
#       字体要装在客户端(笔记本/PC)并在终端里选用; 本脚本适用于
#       服务器本机的图形终端、或本地开发机。
set -euo pipefail

FONT_ZIP_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
TMP_ZIP="${TMPDIR:-/tmp}/FiraCode.zip"

case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux*)               PLATFORM=linux ;;
    Darwin*)              PLATFORM=macos ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM=windows-gitbash ;;
    *)                    PLATFORM=unknown ;;
esac
echo "==> 检测到平台: $PLATFORM"

print_hints() {
    echo ""
    echo "==> 接下来在终端里把字体设为 'FiraCode Nerd Font':"
    echo "    VS Code : \"terminal.integrated.fontFamily\": \"'FiraCode Nerd Font'\""
    case "$PLATFORM" in
        macos)
            echo "    Terminal.app : 设置 → 描述文件 → 文本 → 字体"
            echo "    iTerm2       : Settings → Profiles → Text → Font"
            ;;
        *)
            echo "    GNOME Terminal : 首选项 → 配置文件 → 文本 → 自定义字体"
            echo "    其他终端       : 见 README「字体美化」"
            ;;
    esac
    echo "    注意     : SSH / VS Code Remote 场景字体由客户端渲染, 客户端也要装一份。"
}

font_already_installed() {
    if command -v fc-list >/dev/null 2>&1; then
        # 注意: 不要写 `fc-list | grep -q` —— grep -q 命中后立即退出并关闭管道,
        # 上游 fc-list 会收到 SIGPIPE; set -o pipefail 下整条管道状态为非零,
        # 导致已安装的字体被误判为未装(幂等失效)。用 grep -c 计数规避。
        local N
        # 匹配 'FiraCode Nerd' 而不是裸 'FiraCode': 避免把普通版 Fira Code
        # (brew cask font-fira-code 等途径装的)误判为 Nerd Font 已装。
        N=$(fc-list 2>/dev/null | grep -ci 'FiraCode Nerd' || true)
        [ "${N:-0}" -gt 0 ] && return 0
        return 1
    fi
    if [ -d "$HOME/.local/share/fonts/FiraCode" ] \
        || ls "$HOME/Library/Fonts"/*FiraCodeNerdFont* >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

case "$PLATFORM" in
    windows-gitbash|unknown)
        echo "本脚本只覆盖 Linux / macOS。Windows 客户端请在原生 PowerShell 里执行:"
        echo "  powershell -ExecutionPolicy Bypass -File powershell/install.ps1"
        echo "(它会用 winget 装 starship, 并把 FiraCode Nerd Font 装到用户级字体目录)"
        exit 0
        ;;
esac

if font_already_installed; then
    echo "==> FiraCode 已安装, 跳过(幂等)。"
    print_hints
    exit 0
fi

# macOS 有 brew 优先走 cask(自动管理字体目录与版本)
if [ "$PLATFORM" = macos ] && command -v brew >/dev/null 2>&1; then
    if brew list --cask font-fira-code-nerd-font >/dev/null 2>&1; then
        echo "==> brew 已装 font-fira-code-nerd-font, 跳过(幂等)。"
    else
        echo "==> brew install --cask font-fira-code-nerd-font"
        brew install --cask font-fira-code-nerd-font
    fi
    print_hints
    exit 0
fi

# 其余情况: 下载 zip 解压到用户级字体目录。
# Linux → ~/.local/share/fonts/FiraCode 子目录(fontconfig 递归扫描, 子目录没问题)
# macOS → ttf 平铺进 ~/Library/Fonts:
#   CoreText 对子目录扫描不可靠(装了可能看不到), 且平铺后
#   font_already_installed 的 glob 才能命中, 幂等才成立。
extract_zip() {
    if command -v unzip >/dev/null 2>&1; then
        unzip -oq "$1" -d "$2"
    elif command -v python3 >/dev/null 2>&1; then
        echo "==> 未找到 unzip, 改用 python3 zipfile 解压"
        python3 -m zipfile -e "$1" "$2"
    else
        echo "错误: 解压需要 unzip 或 python3 之一, 都没有请先装一个(Ubuntu: sudo apt install unzip)" >&2
        return 1
    fi
}

echo "==> 下载 FiraCode Nerd Font(约 30MB, 来自 nerd-fonts releases)..."
curl -fSL "$FONT_ZIP_URL" -o "$TMP_ZIP"
if [ "$PLATFORM" = macos ]; then
    EXTRACT_DIR=$(mktemp -d)
    extract_zip "$TMP_ZIP" "$EXTRACT_DIR"
    mv "$EXTRACT_DIR"/*.ttf "$HOME/Library/Fonts/"
    rm -rf "$EXTRACT_DIR"
    rm -f "$TMP_ZIP"
    echo "==> 已把全部 ttf 平铺安装 → ~/Library/Fonts"
else
    mkdir -p "$HOME/.local/share/fonts"
    extract_zip "$TMP_ZIP" "$HOME/.local/share/fonts/FiraCode"
    rm -f "$TMP_ZIP"
    echo "==> 已解压 → ~/.local/share/fonts/FiraCode"
fi

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 || true
    echo "==> fontconfig 缓存已刷新"
else
    echo "警告: 未找到 fc-cache(系统未装 fontconfig)。字体文件已就位,"
    echo "      如需系统级识别可执行: sudo apt install fontconfig"
fi

print_hints
