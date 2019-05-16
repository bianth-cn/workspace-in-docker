#!/bin/bash

# Author        : Tony Bian <biantonghe@gmail.com>
# Last Modified : 2019-05-16 15:18
# Filename      : pyenv.sh

if [ -z "${VIRTUAL_ENV}" ]; then
    source /etc/profile.d/pyenv-init.sh
    pyenv global ${DEFAULT_PY3_VERSION}
fi
