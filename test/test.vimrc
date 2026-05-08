" ~/.vimrc
" vim: syntax=vim ft=vim ff=unix

let mapleader = ' '
let USING_NEOVIM = has('nvim')
let USING_VIM = !USING_NEOVIM

" ============================================================================
" Vim-plug initialization (Get vim-plug by curl)
" ============================================================================
" Avoid modify this section, unless you are very sure of what you are doing

" Vim-plug (plug-manager). Here curl must be installed first -----------------
    " Setup Vim-Plug path for neovim or vim
    let vim_plug_just_installed = 0
    if USING_NEOVIM
        let vim_plug_path = expand('~/.config/nvim/autoload/plug.vim')
    else
        let vim_plug_path = expand('~/.vim/autoload/plug.vim')
    endif

    " Install Vim-Plug for neovim or vim
    if !filereadable(vim_plug_path)
        echo 'Installing Vim-plug...'
        echo ''
        if USING_NEOVIM
            silent !mkdir -p ~/.config/nvim/autoload
            silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
                        \ 'https://raw.githubusercontent.com/junegunn/
                        \vim-plug/master/plug.vim'
        else
            silent !mkdir -p ~/.vim/autoload
            silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
                        \ 'https://raw.githubusercontent.com/junegunn/
                        \vim-plug/master/plug.vim'
        endif
        let vim_plug_just_installed = 1
    endif

    " Manually load vim-plug the first time
    if vim_plug_just_installed
        :execute 'source '.fnameescape(vim_plug_path)
    endif

" ============================================================================
" Vim active plugins
" ============================================================================
" You can disable or add new ones here:

" Declare plug directory -----------------------------------------------------
    " This needs to be here, so vim-plug knows we are declaring the plugins we
    " want to use
    if USING_NEOVIM
        call plug#begin("~/.config/nvim/plugged")
    else
        call plug#begin("~/.vim/plugged")
    endif

    Plug '~/Desktop/vim-markdown-tools'


" End of plugin loading ------------------------------------------------------
    " Tell vim-plug we finished declaring plugins, so it can load them
    call plug#end()

    " NOTE: plugin loading [Now use vim-startuptime plugin instead]
    " -- Check vim startup time and loaded plugins
    " -- vim --startuptime /tmp/startup.log [file_to_test] +q && vim /tmp/startup.log

" ============================================================================
" Install plugins the first time vim runs
" ============================================================================
    if vim_plug_just_installed
        echo "Installing bundles, please ignore key map error messages"
        :PlugInstall
    endif
