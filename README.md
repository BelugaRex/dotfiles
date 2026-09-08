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

## 目录结构

```
dotfiles/
├── install.sh           # 一键安装脚本
├── bashrc.d/custom.sh   # bash 自定义段落（PATH/历史/别名/starship/nvm）
└── config/starship.toml # starship 主题（ohmyzsh ys 复刻，去 VCS 模块）
```
