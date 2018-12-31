" inspired by spf13, 自定义需要的插件集合
if !exists('g:bundle_groups')
    let g:bundle_groups=['python', 'go', 'sh', 'json', 'markdown', 'yaml', 'Dockerfile']
endif

call plug#begin('~/.vim/bundle')

if count(g:bundle_groups, 'go')
    Plug 'fatih/vim-go', { 'do': ':silent GoInstallBinaries' }
endif

call plug#end()
