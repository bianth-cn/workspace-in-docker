#!/bin/bash

# Author        : Tony Bian <biantonghe@gmail.com>
# Last Modified : 2018-12-30 17:49
# Filename      : docker-entrypoint.sh

# for custom versions
ln -sf ${SRC_HOME}/pyenv/versions/* /root/.pyenv/versions
ln -sf ${SRC_HOME}/gvm/gos/* /root/.gvm/gos

# user conf
git config --global user.name "${USER_NAME}"
git config --global user.email "${USER_EMAIL}"
git config --global push.default "${GIT_PUSH_DEFAULT}"

# pip conf
mkdir -p /root/.pip

cat >/root/.pip/pip.conf <<EOF
[global]
trusted-host = ${PIP_TRUSTED_HOST}
index-url = ${PIP_INDEX_URL}
EOF

# spacevim conf
if [[ ${IDE_CONF} == spacevim ]]; then
    ln -sf /root/.SpaceVim /root/.vim
fi

# Use python3 as default
pyenv local ${DEFAULT_PY3_VERSION}

# Welcome
. /usr/local/bin/welcome

exec "$@"
