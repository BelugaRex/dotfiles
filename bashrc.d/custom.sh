# ~/.dotfiles/bashrc.d/custom.sh —— 个人 bash 自定义(通用段落)
# 由 ~/.bashrc 末尾的 dotfiles-loader 加载,兼容任意 Linux 发行版。
# 原始环境: WSL Ubuntu + starship (ohmyzsh ys 风格提示符)。

# ---------- 用户私有 bin ----------
export PATH="$HOME/.local/bin:$PATH"

# ---------- 历史 & 终端行为(无 Ubuntu 默认 bashrc 的机器上也需要) ----------
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# ---------- 常用别名 ----------
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ---------- Starship 提示符(装了才启用) ----------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ---------- nvm(机器上有才生效,没有则静默跳过) ----------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
