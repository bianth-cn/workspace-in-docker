#!/bin/bash

# Author        : Tony Bian <biantonghe@gmail.com>
# Last Modified : 2020-01-05 09:18
# Filename      : admin.sh

DIRNAME=$(
    cd $(dirname $0)
    pwd
)

. ${DIRNAME}/ws.conf

IDE_CONF=k-vim

unset spacevim kvim custom

[[ ${IDE_CONF} == spacevim ]] && spacevim=true
[[ ${IDE_CONF} == k-vim ]] && kvim=true
[[ ${IDE_CONF} == custom ]] && custom=true

WS_NAME=workspace-in-docker
DEV_DOCKER_IMAGE=${HUB_USER}/${WS_NAME}:workspace
FAT_DOCKER_IMAGE=${HUB_USER}/${WS_NAME}:stack

DEV_CONTAINER_NAME_WITH_PROXY=dev-workspace-${IDE_CONF}-withproxy
DEV_CONTAINER_NAME=dev-workspace-${IDE_CONF}

timestamp=$(date +%Y%m%d-%H%M%S)

function colors() {
    red="\033[31m"
    green="\033[32m"
    yellow="\033[33m"
    blue="\033[34m"
    purple="\033[35m"
    skyblue="\033[36m"
    white="\033[37m"
    normal="\033[0m"
}

colors

if [[ $(id -u) == 0 && ! $(hostname) =~ ^(${DEV_CONTAINER_NAME_WITH_PROXY}|${DEV_CONTAINER_NAME})$ ]]; then
    printf "${red}You must not be root!\n${normal}"
    echo
    exit 1
fi

if [[ ! $(hostname) =~ ^(${DEV_CONTAINER_NAME_WITH_PROXY}|${DEV_CONTAINER_NAME})$ ]]; then
    if [[ $(uname) == 'Darwin' ]]; then
        WORKSPACE=/Users/$(whoami)/workspace
        SSH_KEY=/Users/$(whoami)/.ssh
        ECHO='echo -e'
        INTERFACE=en0
        IP="$(ifconfig | grep -A3 ${INTERFACE} | grep " broadcast " | awk -F "[inet ]+" '{print $2}')"
    else
        WORKSPACE=/home/$(whoami)/workspace
        SSH_KEY=/home/$(whoami)/.ssh
        ECHO='echo -e'
        INTERFACE=enp0s3
        IP="$(ifconfig | grep -A1 ${INTERFACE} | grep " broadcast " | awk -F "[inet ]+" '{print $2}')"
    fi
else
    WORKSPACE=$(docker inspect -f \
        '{{println}}{{range .Mounts}}{{.Source}} {{.Destination}}{{println}}{{end}}' \
        $(hostname) | grep -e "workspace$" | awk '{print $1}')
    ECHO='echo -e'
fi

function usage() {
    ${ECHO}
    ${ECHO} "说明:"
    ${ECHO}
    ${ECHO} "    workspace工具管理, workspace分为HOST、DEV、VENV、FAT四层:"
    ${ECHO}
    ${ECHO} "    HOST         dockerd运行环境, workspace最底层"
    ${ECHO} "    DEV          开发专用环境, 在${white}HOST${normal}中使用 \"ws dev [proxy]\" 命令进入"
    ${ECHO} "    VENV         python/go虚拟环境, 在${white}DEV${normal}中使用 \"pe-i\"、\"pes\"、\"go-i\"、\"gos\" 等命令进入"
    ${ECHO} "    FAT          python/go测试专用环境, 在${white}VENV${normal}中使用 \"ws fat [EXPOSE]\" 命令进入"
    ${ECHO}
    ${ECHO} "${white}用法:${normal}"
    ${ECHO}
    ${ECHO} "    ${white}ws <command> [argument]${normal}"
    ${ECHO}
    ${ECHO} "可用 command:"
    ${ECHO}
    ${ECHO} "    ${skyblue}init${normal}         初始化${white}HOST${normal}, 只能在${white}HOST${normal}中使用"
    ${ECHO} "    ${blue}dev${normal}          创建并进入${white}DEV${normal}, 只能在${white}HOST${normal}中使用"
    ${ECHO} "    ${yellow}fat${normal}          创建并进入${white}FAT${normal}, 只能在${white}VENV${normal}中使用"
    ${ECHO} "    clean        清理所有workspace相关容器, 当处于${white}DEV${normal}中时, 仅清理${white}FAT${normal}容器"
    ${ECHO} "    status       打印所有workspace相关容器的状态信息"
    ${ECHO} "    ${green}build${normal}        build指定的docker镜像, 默认build所有workspace相关的docker镜像"
    ${ECHO} "    ${green}push${normal}         push指定的docker镜像到hub.docker.com, 默认push所有workspace相关的docker镜像"
    ${ECHO}
    ${ECHO}
    ${ECHO} "${skyblue}init${normal} 可选 argument:"
    ${ECHO}
    ${ECHO} "    ${skyblue}host${normal}         为${white}HOST${normal}安装字体, 生成ws命令"
    ${ECHO} "    ${skyblue}k-vim${normal}        使用k-vim作为vim-ide的配置"
    ${ECHO} "    ${skyblue}spacevim${normal}     使用spacevim作为vim-ide的配置"
    ${ECHO} "    ${skyblue}custom${normal}       使用custom作为vim-ide的配置, 将挂载vim.conf/custom下的所有文件及目录至容器内的/root目录"
    ${ECHO}
    ${ECHO} "${blue}dev${normal} 可选 argument:"
    ${ECHO}
    ${ECHO} "    ${blue}proxy${normal}        进入${white}DEV${normal}并启用${purple}lantern proxy${normal}, 中国境内专用"
    ${ECHO}
    ${ECHO} "${yellow}fat${normal} 可选 argument:"
    ${ECHO}
    ${ECHO} "    ${yellow}EXPOSE${normal}       添加expose, e.g:"
    ${ECHO} "                     80:80"
    ${ECHO} "                     80:80,443:443"
    ${ECHO} "                     80:80,443:443,3306:3306"
    ${ECHO}
    ${ECHO} "${green}build/push${normal} 可选 argument:"
    ${ECHO}
    ${ECHO} "    ${green}workspace${normal}    ${green}workspace image${normal}, 基于${green}stack image${normal}, 用于配置workspace"
    ${ECHO} "    ${green}stack${normal}        ${green}stack image${normal}, 基于buildpack-deps:bionic, 安装配置python和go"
    ${ECHO} "    ${green}all${normal}          按照${green}stack -> workspace${normal}的顺序build/push所有workspace相关的docker镜像"
    ${ECHO}
    exit 1
}

if [[ $# -gt 2 ]]; then
    usage
fi

function goto() {
    cd ${WORKSPACE}
}

function download_font() {
    url="https://raw.githubusercontent.com/wsdjeg/DotFiles/master/local/share/fonts/$1"
    path="${HOME}/.local/share/fonts/$1"
    curl -s -o "${path}" "${url}"
}

function init_host() {
    if [[ $(uname) == 'Darwin' && ! -d ${HOME}/Library/Fonts ]]; then
        # https://github.com/SpaceVim/SpaceVim/issues/771
        brew tap caskroom/fonts
        brew cask install font-hack-nerd-font
        if [[ $? == 0 ]]; then
            ${ECHO} "${green}Fonts install successfully.${normal}"
        else
            ${ECHO} "${red}Fonts install failed!${normal}"
        fi
    fi

    # if [[ $(uname) == 'Linux' && ! -d ${HOME}/.local/share/fonts ]]; then
    #     download_font "DejaVu Sans Mono Bold Oblique for Powerline.ttf"
    #     download_font "DejaVu Sans Mono Bold for Powerline.ttf"
    #     download_font "DejaVu Sans Mono Oblique for Powerline.ttf"
    #     download_font "DejaVu Sans Mono for Powerline.ttf"
    #     download_font "DroidSansMonoForPowerlinePlusNerdFileTypesMono.otf"
    #     download_font "Ubuntu Mono derivative Powerline Nerd Font Complete.ttf"
    #     download_font "WEBDINGS.TTF"
    #     download_font "WINGDNG2.ttf"
    #     download_font "WINGDNG3.ttf"
    #     download_font "devicons.ttf"
    #     download_font "mtextra.ttf"
    #     download_font "symbol.ttf"
    #     download_font "wingding.ttf"

    #     sudo apt-get update
    #     sudo apt-get install -y --no-install-recommends xfonts-utils

    #     sudo fc-cache -fv >/dev/null
    #     sudo mkfontdir "$HOME/.local/share/fonts" >/dev/null
    #     sudo mkfontscale "$HOME/.local/share/fonts" >/dev/null

    #     if [[ $? == 0 ]]; then
    #         ${ECHO} "${green}Fonts install successfully.${normal}"
    #     else
    #         ${ECHO} "${red}Fonts install failed!${normal}"
    #     fi
    # fi

    sudo mkdir -p ${WORKSPACE}
    ${HARBOR:+mkdir -p /etc/docker/certs.d/${HARBOR}}

    if [[ ${DIRNAME} != ${WORKSPACE}/${WS_NAME} ]]; then
        ${ECHO} "${yellow}Please move the project directory \"${WS_NAME}\" to the workspace path \"${WORKSPACE}\"!${normal}"
        echo
        exit 1
    fi

    if [[ ${IDE_CONF} == k-vim ]]; then
        sed -i "s#Author        : .*>#Author        : ${USER_NAME} <${USER_EMAIL}>#g" ${WORKSPACE}/${WS_NAME}/vim.conf/${IDE_CONF}/vimrc
    fi

    echo "bash ${WORKSPACE}/${WS_NAME}/admin.sh "\$@"" | sudo tee /usr/local/bin/ws
    sudo chmod +x /usr/local/bin/ws
    ${ECHO} "${green}Initial successfully, then you can run the command \"${blue}ws${green}\" anywhere instead of \"admin.sh\".${normal}"
    echo
}

function init_kvim() {
    sed -i 's#^IDE_CONF=.*$#IDE_CONF=k-vim#g' ${WORKSPACE}/${WS_NAME}/admin.sh

    sudo mkdir -p ${WORKSPACE}/.vim
    [[ -d ${WORKSPACE}/.vim/UltiSnips ]] && sudo rm -rf ${WORKSPACE}/.vim/UltiSnips
    [[ -d ${WORKSPACE}/.vim/syntax ]] && sudo rm -rf ${WORKSPACE}/.vim/syntax
    sudo cp -rf ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/UltiSnips ${WORKSPACE}/.vim
    sudo cp -rf ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/syntax ${WORKSPACE}/.vim

    docker run \
        -it --rm \
        --name init_kvim \
        --entrypoint "" \
        -v ${WORKSPACE}/.vim:/root/.vim \
        -v ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/vimrc:/root/.vimrc \
        -v ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/vimrc.bundles:/root/.vimrc.bundles \
        -v ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/ctags:/root/.ctags \
        ${DEV_DOCKER_IMAGE} \
        bash -c "
            set -ex \
                && source /etc/profile \
                && source /root/.gvm/scripts/gvm \
                && gvm use go\${DEFAULT_GO_VERSION} --default \
                \
                && mkdir -p /root/.vim/colors \
                && git clone git://github.com/altercation/vim-colors-solarized.git \
                && mv vim-colors-solarized/colors/solarized.vim /root/.vim/colors \
                \
                && curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
                    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
                \
                && pyenv local \${DEFAULT_PY3_VERSION} \
                && /usr/local/vim.py3/bin/vim +PlugUpdate! +PlugClean! +qall \
                \
                && mkdir -p /root/.vim/plugin \
                && ln -sf /root/.vim/bundle/mru/plugin/mru.vim /root/.vim/plugin/mru.vim
            "
    ${ECHO} ${yellow}vim-ide已配置为k-vim, 重建DEV workspace后生效.${normal}
    ${ECHO}
}

function init_spacevim() {
    sed -i '.bak' 's#^IDE_CONF=.*$#IDE_CONF=spacevim#g' ${WORKSPACE}/${WS_NAME}/admin.sh
    rm -f ${WORKSPACE}/${WS_NAME}/admin.sh.bak

    if [[ ! -d ${WORKSPACE}/.SpaceVim/.git ]]; then
        docker run \
            -it \
            --name init_spacevim \
            --entrypoint "" \
            -v ${WORKSPACE}/.cache/vimfiles:/root/.cache/vimfiles \
            ${DEV_DOCKER_IMAGE} \
            bash -c "
            set -ex \
                && curl -sLf https://spacevim.org/install.sh | bash -s -- --install vim \
                && [[ ! -d /root/.cache/vimfiles/repos/github.com/Shougo/dein.vim/.git ]] \
                && git clone https://github.com/Shougo/dein.vim /root/.cache/vimfiles/repos/github.com/Shougo/dein.vim
            "
        docker cp init_spacevim:/root/.SpaceVim ${WORKSPACE}/.SpaceVim
        docker rm -vf init_spacevim
    else
        docker run \
            -it --rm \
            --name init_spacevim \
            --entrypoint "" \
            -v ${WORKSPACE}/.SpaceVim:/root/.SpaceVim \
            -v ${WORKSPACE}/.cache/vimfiles:/root/.cache/vimfiles \
            ${DEV_DOCKER_IMAGE} \
            bash -c "
            set -ex \
                && cd /root/.SpaceVim \
                && git pull \
                && [[ ! -d /root/.cache/vimfiles/repos/github.com/Shougo/dein.vim/.git ]] \
                && git clone https://github.com/Shougo/dein.vim /root/.cache/vimfiles/repos/github.com/Shougo/dein.vim
            "
    fi
    ${ECHO} ${yellow}vim-ide已配置为spacevim, 重建DEV workspace后生效.${normal}
    ${ECHO}
}

function init_custom() {
    sed -i '.bak' 's#^IDE_CONF=.*$#IDE_CONF=custom#g' ${WORKSPACE}/${WS_NAME}/admin.sh
    rm -f ${WORKSPACE}/${WS_NAME}/admin.sh.bak

    ${ECHO} ${yellow}vim-ide已配置为custom, 重建DEV workspace后生效.${normal}
    ${ECHO}
}

function status() {
    printf "${blue}%-12s  %-7s  %-32s  %-7s  %-20s  %-7s  %-16s  %-16s  %-4s %-20s${normal}\n" \
        "ID" "ROLE" "NAME" "CPU%" "MEM_USAGE / LIMIT" "MEM%" "NET_IO" "BLOCK_IO" "PIDS" "PORTS"

    docker stats --all --no-stream | awk 'NR>1' | while read line; do
        array=($line)

        if [[ ${array[1]} == ${DEV_CONTAINER_NAME} ]]; then
            ROLE=dev
        elif [[ ${array[1]} == ${DEV_CONTAINER_NAME_WITH_PROXY} ]]; then
            ROLE=dev
        elif [[ ${array[1]} == lantern ]]; then
            ROLE=lantern
        elif [[ ${array[1]} =~ fat-.*-.*$ ]]; then
            ROLE=fat
        else
            ROLE=null
        fi

        if [[ ${ROLE} != null ]]; then
            ID=${array[0]}
            NAME=${array[1]}
            CPU=${array[2]}
            MEM_USAGE=${array[3]}
            MEM_LIMIT=${array[5]}
            MEM=${array[6]}
            NET_I=${array[7]}
            NET_O=${array[9]}
            BLOCK_I=${array[10]}
            BLOCK_O=${array[12]}
            PIDS=${array[13]}
            if [[ ${NAME} != lantern ]]; then
                PORTS=$(docker inspect -f \
                    '{{range $port, $conf := .NetworkSettings.Ports}}{{(index $conf 0).HostIp}}:{{(index $conf 0).HostPort}}->{{$port}} {{end}}' \
                    ${NAME} | sed 's/[ \t]*$//g')
            fi

            printf "%-12s  %-7s  %-32s  %-7s  %-8s  / %-8s  %-7s  %-6s  / %-6s  %-6s  / %-6s  %-4s %-20s\n" \
                ${ID} ${ROLE} ${NAME} ${CPU} ${MEM_USAGE} ${MEM_LIMIT} ${MEM} ${NET_I} ${NET_O} ${BLOCK_I} ${BLOCK_O} ${PIDS} ${PORTS}
        fi
    done
    echo
}

function lantern() {
    docker run \
        -it --restart=always \
        --name lantern \
        -p 3128:3128 \
        -d wilon/lantern \
        >/dev/null

    HTTP_PROXY="-e http_proxy=http://$IP:3128"
    HTTPS_PROXY="-e https_proxy=http://$IP:3128"
}

function dev() {
    if docker ps | grep -E "${CONTAINER_NAME}$" >/dev/null; then
        docker exec -it ${CONTAINER_NAME} /bin/bash
    else
        docker run \
            -it \
            --name ${CONTAINER_NAME} \
            --hostname ${CONTAINER_NAME} \
            --network host \
            --restart=always \
            ${HTTP_PROXY} \
            ${HTTPS_PROXY} \
            -e TZ=${TZ} \
            -e IDE_CONF=${IDE_CONF} \
            -e WORKSPACE=${WORKSPACE} \
            -e USER_NAME="'${USER_NAME}'" \
            -e USER_EMAIL=${USER_EMAIL} \
            -e GIT_PUSH_DEFAULT=${GIT_PUSH_DEFAULT} \
            -e PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST} \
            -e PIP_INDEX_URL=${PIP_INDEX_URL} \
            -v /var/run/docker.sock:/var/run/docker.sock:ro \
            ${HARBOR:+-v /etc/docker/certs.d/${HARBOR}:/etc/docker/certs.d/${HARBOR}:ro} \
            -v ${SSH_KEY}:/root/.ssh \
            -v ~/.bash_history:/root/.bash_history \
            -v ${WORKSPACE}:${WORKSPACE} \
            -v ${WORKSPACE}/.pyenv/versions:/root/.pyenv/versions \
            -v ${WORKSPACE}/.gvm/gos:/root/.gvm/gos \
            ${spacevim:+-v ${WORKSPACE}/.cache/vimfiles:/root/.cache/vimfiles} \
            ${spacevim:+-v ${WORKSPACE}/.SpaceVim:/root/.SpaceVim} \
            ${spacevim:+-v ${WORKSPACE}/${WS_NAME}/vim.conf/SpaceVim.d:/root/.SpaceVim.d} \
            ${kvim:+-v ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/vimrc:/root/.vimrc} \
            ${kvim:+-v ${WORKSPACE}/${WS_NAME}/vim.conf/k-vim/vimrc.bundles:/root/.vimrc.bundles} \
            ${kvim:+-v ${WORKSPACE}/.vim:/root/.vim} \
            ${custom:+${volumes}} \
            -w ${WORKSPACE} \
            -d ${DEV_DOCKER_IMAGE} \
            >/dev/null &&
            docker exec -it ${CONTAINER_NAME} /bin/bash -c "welcome && exec /bin/bash"
    fi
}

function fat() {
    docker run \
        -it --rm \
        --name fat-${ENV}-${timestamp} \
        --hostname ${ENV}-${timestamp} \
        -e TZ=${TZ} \
        ${EXPOSE} \
        -v ${WS}:/workspace/${ENV} \
        -w /workspace/${ENV} \
        ${FAT_DOCKER_IMAGE} \
        /bin/bash -c \
        'echo "export PS1=\"[\h]\033[33m&\033[0m \"" >> ~/.bashrc && echo "alias ll=\"ls -lF\"" >> ~/.bashrc && exec /bin/bash'
}

function clean() {
    docker rm -vf $(docker ps -a | grep -E $1 | awk '{print $1}') >/dev/null
}

function build() {
    local role=$1
    local image=$2
    local dockerfile=$3
    local context=$4
    local build_log=/tmp/build_${role}_${timestamp}.log
    docker build -t ${image} -f ${dockerfile} ${context} | tee ${build_log}
    [[ $(tail -1 ${build_log}) == "Successfully tagged ${image}" ]] || exit 1
}

function push() {
    local images=$(echo $1 | sed 's#,# #g')
    docker login -u ${HUB_USER}
    for image in ${images}; do
        docker push ${image}
    done
}

case $1 in
    goto)
        goto
        ;;
    init)
        if [[ $(hostname) =~ ^(${DEV_CONTAINER_NAME_WITH_PROXY}|${DEV_CONTAINER_NAME})$ ]]; then
            ${ECHO} "${yellow}You are already in ${white}DEV workspace${yellow} \"$(hostname)\", ignore init.${normal}"
            echo
            exit 1
        fi

        if [[ $2 == host || -z $2 ]]; then
            init_host
        elif [[ $2 == k-vim ]]; then
            init_kvim
        elif [[ $2 == spacevim ]]; then
            init_spacevim
        elif [[ $2 == custom ]]; then
            init_custom
        else
            usage
        fi
        ;;
    dev)
        if [[ $(hostname) =~ ^(${DEV_CONTAINER_NAME_WITH_PROXY}|${DEV_CONTAINER_NAME})$ ]]; then
            ${ECHO} "${yellow}You are already in ${white}DEV workspace${yellow} \"$(hostname)\".${normal}"
            echo
            exit 1
        fi

        TZ="$(ls -la /etc/localtime | cut -d/ -f8-9)"

        if [[ ${IDE_CONF} == custom ]]; then
            files=$(ls -A ${WORKSPACE}/${WS_NAME}/vim.conf/custom)

            volumes=""
            for v in ${files}; do
                if [[ ${v} != '.python-version' ]]; then
                    volumes="${volumes} -v ${WORKSPACE}/${WS_NAME}/vim.conf/custom/${v}:/root/${v}"
                fi
            done
        fi

        if [[ -n $2 && $2 != 'proxy' ]]; then
            usage
        elif [[ -n $2 && $2 == 'proxy' ]]; then
            if [[ -z $(docker ps | grep -E "${DEV_CONTAINER_NAME_WITH_PROXY}$") ]] >/dev/null; then
                if [[ -n $(docker ps -a | grep lantern) ]]; then
                    clean lantern
                fi
                lantern
            else
                if [[ -z $(docker ps -a | grep lantern) ]]; then
                    lantern
                fi
            fi
            CONTAINER_NAME=${DEV_CONTAINER_NAME_WITH_PROXY}
            init_host
            dev
        else
            CONTAINER_NAME=${DEV_CONTAINER_NAME}
            init_host
            dev
        fi
        ;;
    fat)
        if [[ ! $(hostname) =~ ^(${DEV_CONTAINER_NAME_WITH_PROXY}|${DEV_CONTAINER_NAME})$ ]]; then
            ${ECHO} "${yellow}Please use the command \"ws dev [proxy]\" to enter ${white}DEV workspace${yellow} first.${normal}"
            echo
            exit 1
        fi

        if [[ -z $VIRTUAL_ENV ]]; then
            ${ECHO} "${yellow}Please use the command \"pes\" or \"gos\" to enter ${white}VENV workspace${yellow} first.${normal}"
            echo
            exit 1
        fi

        TZ=${TZ}

        if [[ -z $GOPATH ]]; then
            ENV=$(echo $VIRTUAL_ENV | awk -F '/' '{print $(NF-1)}')
            WS=${WORKSPACE}/$(echo ${VIRTUAL_ENV} | awk -F '/' '{for (i=1;i<NF;i++) if(i>3) printf("%s/",$i)}')
        else
            ENV=${VIRTUAL_ENV}
            WS=${WORKSPACE}/$(echo ${GOPATH} | awk -F ":" '{print $1}' | awk -F '/' '{for (i=1;i<=NF;i++) if(i>3) printf("%s/",$i)}')bin
        fi

        if [[ -n $2 ]]; then
            if [[ $2 =~ [1-9][0-9]{1,4}:[1-9][0-9]{1,4}(,[1-9][0-9]{1,4}:[1-9][0-9]{1,4})*$ ]]; then
                EXPOSES=($(echo $2 | sed 's/,/ /g'))
                EXPOSE=""
                for expose in "${EXPOSES[@]}"; do
                    EXPOSE="${EXPOSE} -p ${expose}"
                done
            else
                ${ECHO} "${red}The EXPOSE argument is invalid!${normal}"
                ${ECHO} "${yellow}It must conform to the following regular expression:${normal}"
                ${ECHO} '    [1-9][0-9]{2,4}:[1-9][0-9]{2,4}(,[1-9][0-9]{2,4}:[1-9][0-9]{2,4})*$'
                ${ECHO} "${yellow}e.g:${normal}"
                ${ECHO} "    80:80"
                ${ECHO} "    80:80,443:443"
                ${ECHO} "    80:80,443:443,3306:3306"
                echo
                exit 1
            fi
        fi
        fat
        ;;
    clean)
        if [[ -n $(docker ps -a | grep -E "fat-.*-.*$" | grep ${FAT_DOCKER_IMAGE}) ]]; then
            clean "fat-.*-.*$"
        fi

        if [[ $(hostname) =~ ^(${DEV_CONTAINER_NAME_WITH_PROXY}|${DEV_CONTAINER_NAME})$ ]]; then
            ${ECHO} "${yellow}You are already in ${white}DEV workspace${yellow} \"$(hostname)\", ignore clean ${white}DEV workspace${yellow} containers.${normal}"
            echo
            exit 1
        fi

        if [[ -n $(docker ps -a | grep lantern) ]]; then
            clean lantern
        fi

        if [[ -n $(docker ps -a | grep ${DEV_CONTAINER_NAME_WITH_PROXY}) ]]; then
            clean ${DEV_CONTAINER_NAME_WITH_PROXY}
        fi

        if [[ -n $(docker ps -a | grep ${DEV_CONTAINER_NAME}) ]]; then
            clean ${DEV_CONTAINER_NAME}
        fi
        ;;
    build)
        ROLE=$2
        if [[ -z ${ROLE} ]]; then
            ROLE="all"
        fi

        if [[ ${ROLE} == "workspace" ]]; then
            build ${ROLE} ${DEV_DOCKER_IMAGE} ${DIRNAME}/docker/Dockerfile.${ROLE} ${DIRNAME}
        elif [[ ${ROLE} == "stack" ]]; then
            build ${ROLE} ${FAT_DOCKER_IMAGE} ${DIRNAME}/docker/Dockerfile.${ROLE} ${DIRNAME}
        elif [[ ${ROLE} == "all" ]]; then
            build stack ${FAT_DOCKER_IMAGE} ${DIRNAME}/docker/Dockerfile.stack ${DIRNAME}
            build workspace ${DEV_DOCKER_IMAGE} ${DIRNAME}/docker/Dockerfile.workspace ${DIRNAME}
        else
            usage
        fi
        ;;
    push)
        ROLE=$2
        if [[ -z ${ROLE} ]]; then
            ROLE="all"
        fi
        if [[ ! ${ROLE} =~ ^(workspace|stack|all)$ ]]; then
            usage
        fi
        if [[ ${ROLE} == "all" ]]; then
            push ${FAT_DOCKER_IMAGE},${DEV_DOCKER_IMAGE}
        else
            push ${HUB_USER}/${WS_NAME}:${ROLE}
        fi
        ;;
    status)
        status
        ;;
    *)
        usage
        ;;
esac
