# dotfiles PowerShell profile —— Windows 原生(PowerShell 5.1 / pwsh 7+)使用
# 用法:
#   推荐: 在仓库根目录执行 powershell -ExecutionPolicy Bypass -File .\powershell\install.ps1
#         它会自动装 starship 与字体, 并把本文件以 loader 方式挂进 $PROFILE。
#   以下为手动配置的完整步骤:
#   1. 安装 starship(任选其一):
#        winget install Starship.Starship        # 官方推荐
#        scoop install starship                  # 或 scoop
#   2. 查看 profile 路径:      echo $PROFILE
#      (Windows PowerShell 5.1 时为 文档\WindowsPowerShell\Microsoft.PowerShell_profile.ps1;
#       pwsh 7+ 时为 文档\PowerShell\Microsoft.PowerShell_profile.ps1)
#   3. 把本文件内容追加进该文件(可先备份);目录不存在则新建
#   4. 把仓库 config/starship.toml 复制到 ~/.config/starship.toml
#      (即 C:\Users\<你>\.config\starship.toml,~/.config 目录需自建)
#   5. 重开 PowerShell

# ---------- Starship 提示符(装了才启用) ----------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ---------- 历史行为(对齐 bash 版 custom.sh) ----------
Set-PSReadLineOption -HistoryNoDuplicates          -ErrorAction SilentlyContinue
Set-PSReadLineOption -MaximumHistoryCount 10000    -ErrorAction SilentlyContinue
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue

# ---------- 常用别名 / 函数(对齐 bash 版 ll / la / l) ----------
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Name @args }
function l  { Get-ChildItem -Name @args }
