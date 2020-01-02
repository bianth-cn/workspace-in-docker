                                           ##        .
                                     ## ## ##       ==
                                  ## ## ## ##      ===
                              /___/ ===
                         ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
                              \______ o          __/
                               \   \        __/
                                 \____\______/

# 欢迎来到`Tony`的工作空间

## 这是什么？

- 专为`DevOps`人员设计的效率工具，旨在提高开发和文本处理的效率
- 使用`docker`封装的`workspace`，包含`vim-ide`以及常用工具集
- 支持`python`、`go`、`shell`的代码高亮, 语法检查，格式化, 自动补全, 查看文档、定义、引用, 以及[`REPL`](https://github.com/sillybun/vim-repl)等功能
- 支持`markdown`、`json`、`yaml`、`Dockerfile`等文本格式的代码高亮, 语法检查，格式化等功能

## 这里有什么？

- 预装了[`pyenv`](https://github.com/pyenv/pyenv)、[`pipenv`](https://github.com/pypa/pipenv)、`python2.7`、`python3.6`的`python`开发环境
- 预装了[`gvm`](https://github.com/moovweb/gvm)、[`glide`](https://github.com/Masterminds/glide)、`go1.13`的`go`开发环境
- 基于[`k-vim`](https://github.com/wklken/k-vim)做了大量扩展和调整的`vim-ide`
- 支持切换[`SpaceVim`](https://github.com/SpaceVim/SpaceVim)作为`vim-ide`的配置
- 支持使用自定义配置作为`vim-ide`的配置
- 预装了`docker-client`、`docker-compose`、`docker-tags`、[`dive`](https://github.com/wagoodman/dive)等`docker`管理工具
- 预装了`git`、[`git-flow`](https://nvie.com/posts/a-successful-git-branching-model/)等代码版本及开发工作流程管理工具
- 对以上工具进行了封装，实现项目隔离、规范项目目录结构及简化开发流程
- 预装了常用的`linux`系统工具、网络工具和包管理工具.

## 核心设计

- `workspace`的四层抽象

  - `HOST`: `dockerd`运行环境, `workspace`最底层
  - `DEV`: 开发专用环境, 在`HOST`中使用 `ws dev [proxy]` 命令进入, 命令行提示符为蓝色`#`, 启用`proxy`时命令行提示符为蓝色背景`#`
  - `VENV`: `python`/`go`虚拟环境, 在`DEV`中使用 `pe-i`、`pes`、`go-i`、`gos` 等命令进入, 命令行提示符为天蓝色`$`
  - `FAT`: 测试专用环境, 在`VENV`中使用 `ws fat [EXPOSE]` 命令进入, 命令行提示符为黄色`&`

- 可移植性

  - 使用`docker`封装
  - 充分利用`--volume`功能解耦并保留`workspace`状态
  - 仅依赖`dockerd`

- 通用性和性能

  - 一种编辑器搞定多种语言和文本格式的开发、编辑需求
  - 基于`vim`实现`ide`的功能, 同时获得高于常规`ide`的性能

## 命令行工具

- [`ws`](./scripts/usage/ws.md): `workspace`管理入口
- [`pye`](./scripts/usage/pye.md): `python`开发任务管理入口
- [`goe`](./scripts/usage/goe.md): `go`开发任务管理入口
- [`gite`](./scripts/usage/gite.md): `git`相关命令入口
- `gh-md-toc`: 对[`gh-md-toc`](https://github.com/ekalinin/github-markdown-toc)的封装, 可对指定目录下的所有`markdown`格式文件生成`TOC
- `vimdiff`: 对`vimdiff`及[`vim-dirdiff`](https://github.com/will133/vim-dirdiff)的封装, 可比对指定目录的差异
- `guide`: 查看使用手册(施工中……)
- `welcome`: 查看欢迎界面
- 更多工具请查看项目根目录下的`scripts`目录

## 安装环境要求

- 支持`macOS`(仅对`10.14.x`版本做了测试)
- 支持`Ubuntu`(仅对`18.04`版本做了测试)
- 使用非`root`用户
- 预装`docker-ce`、`curl`、`git`

## 安装方法

```bash
# 下载项目代码, 此处强制要求项目目录为${HOME}/workspace/workspace-in-docker
git clone https://github.com/TonyBian/workspace-in-docker.git ${HOME}/workspace/workspace-in-docker


# 初始化HOST workspace
# 安装字体, 并生成可随处执行的ws命令以替代admin.sh
bash ${HOME}/workspace/workspace-in-docker/admin.sh init


# 初始化vim-ide, 可选k-vim、spacevim以及自定义配置

## 选择k-vim时, 首次执行将根据vim配置下载并安装插件, 耗时较长
## 完成初始化后再次执行将检查并升级已安装的插件

## 选择spacevim时, 首次执行将下载SpaceVim项目及dein插件管理工具
## 完成初始化后再次执行将升级SpaceVim
## 在DEV workspace中, 首次打开vim将根据配置下载并安装插件

## 选择custom时, 需要在DEV workspace中手动根据vim配置安装插件
ws init {k-vim|spacevim|custom}
```

## 使用方法

```bash
# 修改自定义配置
# USER_NAME及USER_EMAIL: 修改git全局配置及源码文件的Author信息
# HUB_USER: 当使用自定义docker image时请修改此参数
# HARBOR: 此参数不为空时, DEV workspace容器将挂载指定harbor地址的证书, 以获取访问指定harbor的权限
# GIT_PUSH_DEFAULT: 详见https://git-scm.com/docs/git-config#git-config-pushdefault
# PIP_TRUSTED_HOST: 指定pip源可信host
# PIP_INDEX_URL: 指定pip源
${HOME}/workspace/workspace-in-docker/ws.conf


# 进入DEV workspace, 可选使用代理翻墙
# 初次使用时需要下载所需docker image, 耗时较长
ws dev [proxy]


# 创建python/go项目, 进入VENV workspace, 并修改$HOME为项目目录
# 如果指定了当前没有安装的版本, 将提示是否自动安装, 安装可能耗时较长
# python项目目录为/root/workspace/py-projects/<project_version>/<project_name>
# go项目目录为/root/workspace/go-projects/<project_version>/<project_name>
# 初始化项目的git仓库, 并创建.gitignore
# 初始化包管理文件

## python项目
pe-i <project_name> [project_version]

## go项目
go-i <project_name> [project_version]


# 切换到已存在VENV workspace

## python项目
pes <project_num>

## go项目
gos <project_num>


# 包管理
# 需要先切换到项目对应的VENV workspace
# 可使用pye及goe命令获取详细信息

## python项目
pye

## go项目
goe


# vim-ide
# 配置文件放在项目目录下的vim.conf目录中
# 介绍两个使用k-vim配置时的实用功能
# 基于vim8.1的内置terminal功能实现

## REPL, 交互式编程
## 详见https://github.com/sillybun/vim-repl
## 键位映射
let g:sendtorepl_invoke_key = "ww"
nnoremap rr :REPLToggle<Cr>

tnoremap <C-h> <C-w><C-h>
tnoremap <C-j> <C-w><C-j>
tnoremap <C-k> <C-w><C-k>
tnoremap <C-l> <C-w><C-l>

## 以指定高度开启内置terminal
## 键位映射
nnoremap tm :call OpenTerminal()<cr>

## 更多vim配置请阅读vim.conf下的配置文件
```

## `trouble shooting`

- `vim`界面状态栏乱码或其他显示异常

  - 一般由字体或终端配置问题导致, 详见[`macOS`环境解决方案](https://github.com/SpaceVim/SpaceVim/issues/771)

- `vim`自动补全失效或报错

  - `vim`的使用依赖于环境变量, 当切换到`VENV workspace`时，需要重新启动`vim`使环境变量生效

- 修改`vim`配置后配置失效

  - `vim`的配置文件在项目中`vim.conf`目录下, 通过`--volume`的方式挂载到容器中, 直接修改该目录下的配置文件会导致挂载出现问题
  - 可以通过修改`/root`目录下的`.vimrc`、`.vimrc.bundles`、`.SpaceVim.d/`来调整`vim`配置

- `vim`启动较慢

  - `vim`每次启动时需要加载插件和配置
  - 最佳实践是启动`vim`之后, 一切文件操作都在`vim`内部进行, 充分利用`window/tab/buffer`及文件管理插件, 避免频繁的启动和关闭`vim`
  - 当需要切换`VENV`或`python`版本时, 必须在切换后重新启动`vim`使环境变量生效
  - 当需要同时在多个`VENV`下工作时, 最好每个`VENV`使用一个独立的终端窗口

- `vim`使用`hjkl`移动光标导致`cpu`使用率升高，性能下降

  - 由`syntax`导致, 详见[Syntax highlighting causes terrible lag in Vim](https://stackoverflow.com/questions/19030290/syntax-highlighting-causes-terrible-lag-in-vim)
  - 最佳实践是少用`hjkl`, 多用其他更高效的光标移动方法
    > 段落引用
