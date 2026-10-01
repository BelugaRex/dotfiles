# ~/.dotfiles/bashrc.d/custom.sh —— 个人 shell 自定义(跨平台)
# 由 ~/.bashrc 或 ~/.zshrc 末尾的 dotfiles-loader 加载,bash(≥3.2)与 zsh 均可直接 source。
# 适配:Linux(任意发行版 / WSL) / macOS(bash 或 zsh) / Windows Git Bash(MSYS2)。
# Windows 原生 PowerShell 不使用本文件,见仓库 powershell/profile.ps1。
# 原始环境: WSL Ubuntu + starship (ohmyzsh ys 风格提示符)。
#
# 写法约束: 只用 POSIX 语法(case / [ ] / alias),不用 [[ ]] 与数组,保证 zsh 可加载。

# ---------- 平台探测 ----------
case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux*)               DOTFILES_OS=linux ;;
    Darwin*)              DOTFILES_OS=macos ;;
    MINGW*|MSYS*|CYGWIN*) DOTFILES_OS=windows ;;
    *)                    DOTFILES_OS=unknown ;;
esac

# ---------- 用户私有 bin(幂等,避免重复入链) ----------
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# macOS: 若通过 Homebrew 装了 GNU coreutils,让 ls/grep 等用 GNU 版本
if [ "$DOTFILES_OS" = macos ] && command -v brew >/dev/null 2>&1; then
    GNU_PATH="$(brew --prefix coreutils 2>/dev/null)/libexec/gnubin"
    [ -d "$GNU_PATH" ] && export PATH="$GNU_PATH:$PATH"
fi

# ---------- 历史 & 终端行为(shopt 仅 bash 有效,zsh 自动跳过) ----------
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
if [ -n "${BASH_VERSION-}" ]; then
    shopt -s histappend 2>/dev/null
    shopt -s checkwinsize 2>/dev/null
fi
if [ -n "${ZSH_VERSION-}" ]; then
    # zsh 的等效行为: 多会话共享历史 + 忽略重复与空格开头的命令
    setopt histignorealldups sharehistory 2>/dev/null
fi

# ---------- 常用别名 ----------
# 颜色支持: 有 dircolors 的 GNU 环境用 --color;macOS(BSD ls)退回 -G
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
else
    case "$DOTFILES_OS" in
        macos) alias ls='ls -G' ;;
        *)     alias ls='ls --color=auto' ;;
    esac
    alias grep='grep --color=auto'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ---------- Starship 提示符(装了才启用,自动匹配当前 shell) ----------
if command -v starship >/dev/null 2>&1; then
    if [ -n "${ZSH_VERSION-}" ]; then
        eval "$(starship init zsh)"
    elif [ -n "${BASH_VERSION-}" ]; then
        eval "$(starship init bash)"
    fi
fi

# ---------- nvm(机器上有才生效,没有则静默跳过) ----------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
