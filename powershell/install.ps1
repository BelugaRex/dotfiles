# dotfiles —— Windows 原生 PowerShell 一键安装(PowerShell 5.1+ / pwsh 7+, 幂等, 无需管理员)
# 在仓库根目录执行:
#   powershell -ExecutionPolicy Bypass -File .\powershell\install.ps1
# 内容: winget 装 starship + FiraCode Nerd Font(用户级) + starship.toml + $PROFILE loader。
# 注意: PowerShell 5.1 与 pwsh 7 的 $PROFILE 是两个独立文件, 两个宿主都想要就各跑一次。

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$ProgressPreference = 'SilentlyContinue'    # 否则 PS5.1 的下载进度条会拖慢数倍

$RepoRoot = Split-Path -Parent $PSScriptRoot
Write-Host "==> 仓库: $RepoRoot"

# ---------- 1. starship ----------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Write-Host "==> 已检测到 starship, 跳过"
} else {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "==> winget install Starship.Starship"
        winget install -e --id Starship.Starship --silent --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "==> scoop install starship"
        scoop install starship
    } else {
        Write-Warning "未找到 winget / scoop, 请手动安装 starship(https://starship.rs)后重跑本脚本"
    }
}
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    Write-Warning "当前会话 PATH 里还没有 starship(winget 安装的 PATH 要新开终端才生效); profile 已配好, 重开 PowerShell 即可"
}

# ---------- 2. FiraCode Nerd Font(用户级: 拷文件 + 写 HKCU 注册表) ----------
# per-user 安装(Win10 1809+): $env:LOCALAPPDATA\Microsoft\Windows\Fonts + HKCU Fonts 注册表值
$FontDir  = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$FontsReg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -ItemType Directory -Force -Path $FontDir | Out-Null
$Fonts = [ordered]@{
    'FiraCodeNerdFont-Regular.ttf'     = 'FiraCode Nerd Font (TrueType)'
    'FiraCodeNerdFont-Bold.ttf'        = 'FiraCode Nerd Font Bold (TrueType)'
    'FiraCodeNerdFontMono-Regular.ttf' = 'FiraCode Nerd Font Mono (TrueType)'
    'FiraCodeNerdFontMono-Bold.ttf'    = 'FiraCode Nerd Font Mono Bold (TrueType)'
}
foreach ($File in $Fonts.Keys) {
    $Dest = Join-Path $FontDir $File
    if (Test-Path $Dest) { Write-Host "==> 已有 $File, 跳过"; continue }
    try {
        $Url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$File"
        Write-Host "==> 下载 $File"
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
        New-ItemProperty -Path $FontsReg -Name $Fonts[$File] -Value $Dest -PropertyType String -Force | Out-Null
    } catch {
        Write-Warning "下载/注册 $File 失败: $($_.Exception.Message)(重跑本脚本可续传)"
    }
}
Write-Host "==> 字体目录: $FontDir (已运行的程序需重开才会识别新字体)"

# ---------- 3. starship.toml(复制; Windows 软链需开发者模式/管理员, 不划算) ----------
$ConfigDir = Join-Path $HOME '.config'
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
Copy-Item -Force -Path (Join-Path $RepoRoot 'config\starship.toml') -Destination (Join-Path $ConfigDir 'starship.toml')
Write-Host "==> 已复制 starship.toml → $ConfigDir\starship.toml (仓库更新后重跑本脚本覆盖)"

# ---------- 4. $PROFILE loader(幂等; 写入 CurrentUserAllHosts, VS Code 终端也生效) ----------
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
    Write-Host "==> 已创建 $ProfilePath"
}
if (Select-String -Path $ProfilePath -Pattern 'dotfiles-loader' -Quiet) {
    Write-Host "==> $ProfilePath 已含 dotfiles loader, 跳过"
} else {
    Add-Content -Path $ProfilePath -Value "`r`n# >>> dotfiles-loader >>>`r`n. `"$RepoRoot\powershell\profile.ps1`"`r`n# <<< dotfiles-loader <<<"
    Write-Host "==> 已向 $ProfilePath 追加 loader"
}

Write-Host ""
Write-Host "完成! 新开 PowerShell 生效; 终端字体选 'FiraCode Nerd Font'(见 README「字体美化」)。"