if [[ -z $VIRTUAL_ENV ]]; then
    if [[ $(hostname) =~ dev-workspace-.*-withproxy ]]; then
        export PS1="[\w]\e[7;34m#\e[0m "
    else
        export PS1="[\w]\e[34m#\e[0m "
    fi
fi
