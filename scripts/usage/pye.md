## `python`开发任务管理入口

包含各命令行工具的完整命令、别名以及说明

```bash
pe    pipenv
pe-i  pipenv-init       初始化python项目, 并进入项目的虚拟环境
pe-u  pipenv-uninstall  递归删除python模块及其依赖, 如果依赖被其他模块引用则保留此依赖
pes   pipenv-shell      进入指定python项目的虚拟环境
pei   pipenv-install    使用pipenv安装python模块
peg   pipenv graph      打印出已安装的模块及依赖项的树状图
pel   pipenv lock       生成Pipfile.lock
peu   pipenv update     运行pel, 并安装所有Pipfile.lock中指定的模块
```
