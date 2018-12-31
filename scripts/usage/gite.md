## `git`相关命令入口

包含各命令行工具的完整命令及别名

```bash
git co    checkout
git cm    commit -s -a
git ss    status
git br    branch -a
git cp    cherry-pick -s -x
git lr    ls-remote origin
git ls    log --color --graph

lgit      git add --all "$1" && git commit -s -a -m "$2" && git push origin --all

gitf      git flow
gitfi     git flow init
gitff     git flow feature
gitfb     git flow bugfix
gitfr     git flow release
gitfh     git flow hotfix
gitfs     git flow support
gitfl     git flow log
gitfv     git flow version
gitfc     git flow config
```
