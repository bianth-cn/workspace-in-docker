# Fix the ctrl+a/ctrl+e exception under the command line
export TERM=dumb

alias ls='TERM=xterm ls --color=auto'
alias ll='ls -lF'
alias ssh='TERM=xterm ssh'
alias cdws="cd ${WORKSPACE}"

alias ansible="TERM=xterm ansible"
alias ansible-playbook="TERM=xterm ansible-playbook"

stty erase ^h
stty erase ^?
