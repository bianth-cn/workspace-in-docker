## `workspace`管理入口

`workspace`分为`HOST`、`DEV`、`VENV`、`FAT`四层

- `HOST`: `dockerd`运行环境, `workspace`最底层
- `DEV`: 开发专用环境, 在`HOST`中使用 `ws dev [proxy]` 命令进入, 命令行提示符为蓝色`#`, 启用`proxy`时命令行提示符为蓝色背景`#`
- `VENV`: `python`/`go`虚拟环境, 在`DEV`中使用 `pe-i`、`pes`、`go-i`、`gos` 等命令进入, 命令行提示符为天蓝色`$`
- `FAT`: 测试专用环境, 在`VENV`中使用 `ws fat [EXPOSE]` 命令进入, 命令行提示符为黄色`&`

```bash
用法:

    ws <command> [argument]

可用 command:

    init         初始化HOST, 只能在HOST中使用
    dev          创建并进入DEV, 只能在HOST中使用
    fat          创建并进入FAT, 只能在VENV中使用
    clean        清理所有workspace相关容器, 当处于DEV中时, 仅清理FAT容器
    status       打印所有workspace相关容器的状态信息
    build        build指定的docker镜像, 默认build所有workspace相关的docker镜像
    push         push指定的docker镜像到hub.docker.com, 默认push所有workspace相关的docker镜像


init 可选 argument:

    host         为HOST安装字体, 生成ws命令
    k-vim        使用k-vim作为vim-ide的配置
    spacevim     使用spacevim作为vim-ide的配置
    custom       使用custom作为vim-ide的配置, 将挂载vim.conf/custom下的所有文件及目录至容器内的/root目录

dev 可选 argument:

    proxy        进入DEV并启用lantern proxy, 中国境内专用

fat 可选 argument:

    EXPOSE       添加expose, e.g:
                     80:80
                     80:80,443:443
                     80:80,443:443,3306:3306

build/push 可选 argument:

    workspace    workspace image, 基于stack image, 用于配置workspace
    stack        stack image, 基于buildpack-deps:bionic, 安装配置python和go
    all          按照stack -> workspace的顺序build/push所有workspace相关的docker镜像
```
