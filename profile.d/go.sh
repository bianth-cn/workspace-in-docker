source /root/.gvm/scripts/gvm
alias gvm="TERM=xterm gvm"
export GO15VENDOREXPERIMENT=1

create_enviroment() {
    new_env_file=$GVM_ROOT/environments/$GO_NAME
    echo "export GVM_ROOT; GVM_ROOT=\"$GVM_ROOT\"" >"$new_env_file"
    echo "export gvm_go_name; gvm_go_name=\"$GO_NAME\"" >>"$new_env_file"
    echo "export gvm_pkgset_name; gvm_pkgset_name=\"global\"" >>"$new_env_file"
    echo "export GOROOT; GOROOT=\"\$GVM_ROOT/gos/$GO_NAME\"" >>"$new_env_file"
    echo "export GOPATH; GOPATH=\"\$GVM_ROOT/pkgsets/$GO_NAME/global\"" >>"$new_env_file"
    echo "export GVM_OVERLAY_PREFIX; GVM_OVERLAY_PREFIX=\"\${GVM_ROOT}/pkgsets/${GO_NAME}/global/overlay\"" >>"$new_env_file"
    echo "export PATH; PATH=\"\${GVM_ROOT}/pkgsets/${GO_NAME}/global/bin:\${GVM_ROOT}/gos/${GO_NAME}/bin:\${GVM_OVERLAY_PREFIX}/bin:\${GVM_ROOT}/bin:\${PATH}\"" >>"$new_env_file"
    echo "export LD_LIBRARY_PATH; LD_LIBRARY_PATH=\"\${GVM_OVERLAY_PREFIX}/lib:\${LD_LIBRARY_PATH}\"" >>"$new_env_file"
    echo "export DYLD_LIBRARY_PATH; DYLD_LIBRARY_PATH=\"\${GVM_OVERLAY_PREFIX}/lib:\${DYLD_LIBRARY_PATH}\"" >>"$new_env_file"
    echo "export PKG_CONFIG_PATH; PKG_CONFIG_PATH=\"\${GVM_OVERLAY_PREFIX}/lib/pkgconfig:\${PKG_CONFIG_PATH}\"" >>"$new_env_file"
    # gvm pkgset create global
    unset GOPATH
}

create_global_package_set() {
    # Create the global package set folder
    mkdir -p "$GVM_ROOT/pkgsets/$GO_NAME"
    GVM_OVERLAY_ROOT="${GVM_ROOT}/pkgsets/${GO_NAME}/global/overlay"
    mkdir -p "${GVM_OVERLAY_ROOT}/lib/pkgconfig"
    mkdir -p "${GVM_OVERLAY_ROOT}/bin"
}

GO_VERSIONS=$(ls ${GVM_ROOT}/gos)

for version in ${GO_VERSIONS}; do
    GO_NAME=${version}
    if [[ ! -d ${GVM_ROOT}/environments/${GO_NAME} ]]; then
        create_enviroment
        create_global_package_set
    fi
done

alias go-i='go-init'
alias gos='go-shell'
alias gog='glide get'
alias goi='glide install'
alias gou='glide update'
