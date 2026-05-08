" ==============================================================================
" Plugin:        vim-markdown-tools
" File:          markdown_tools.vim
" Description:   A comprehensive Markdown toolkit for Vim/Neovim.
"
" Features:
"   - 📝 Auto-loads customizable templates for new Markdown files.
"   - 👁️ Seamless previewing and exporting (Pandoc HTML, Marp presentations).
"   - 🔗 Advanced Path Management: Toggle between Absolute, Relative, and $HOME
"     environment paths instantly for files and links under the cursor.
"   - 📂 Smart Note Moving: Safely relocates Markdown files and migrates
"     associated './figures' directories.
"   - 📸 Native Flameshot integration for capturing and pasting scaled screenshots.
"   - 🔍 Search Tools: Instantly populate Quickfix/Location lists with all
"     embedded websites, file paths, or markdown headers.
"   - ⚡ Quick-insert mappings for images, videos, checkboxes, and tables.
"
" Maintainer:    JordanWu1997 <jordankhwu@gmail.com>
" Repository:    https://github.com/JordanWu1997/vim-markdown-tools
" Version:       1.0.0
" License:       MIT License
" ==============================================================================

if exists('g:loaded_markdown_tools')
    finish
endif
let g:loaded_markdown_tools = 1

" --- Configuration Defaults ---
" Get the absolute path to the root of this plugin directory
let s:plugin_root = expand('<sfile>:p:h:h')

" Set default paths to point to the bundled folders
let g:md_tools_template_dir = get(g:, 'md_tools_template_dir', s:plugin_root . '/templates/')
let g:md_tools_table_template = get(g:, 'md_tools_table_template', g:md_tools_template_dir . 'table.html')
let g:md_tools_browser = get(g:, 'md_tools_browser', $BROWSER)
let g:md_tools_use_template = get(g:, 'md_tools_use_template', 1)

" --- Helper Functions ---

function! s:InsertMarkdownTemplate() abort
    if line('$') == 1 && empty(getline(1))
        let l:template = g:md_tools_template_dir . 'markdown_template.md'
        if filereadable(l:template)
            exec '0r' l:template
            keeppatterns silent! %s/YYYY-mm-DD HH:MM:SS/\=strftime("%Y-%m-%d %T")/g
        endif
    endif
endfunction

function! MarkdownTools_ToggleEnvPath(char)
    let l:word = expand('<cfile>')
    let l:home = $HOME
    if l:word =~? '^$HOME\>'
        let l:subpath = substitute(l:word, '^$HOME', '', '')
        let l:absolute = l:home . l:subpath
        let l:result = substitute(l:absolute, '/\+$', '', '')
    elseif l:word =~? '^' . escape(l:home, '/')
        let l:subpath = substitute(l:word, '^' . escape(l:home, '/'), '', '')
        let l:result = '$HOME' . l:subpath
    else
        let l:result = l:word
    endif
    execute "normal! ci" . a:char . l:result
endfunction

function! MarkdownTools_ConvertRelativeToAbsolute(char)
    let l:path = expand('<cfile>:p')
    let l:absolute = trim(system(printf('realpath %s', shellescape(l:path))))
    exe "normal! ci" . a:char . l:absolute
endfunction

function! MarkdownTools_ConvertAbsoluteToRelative(char)
    let l:path = expand('<cfile>')
    let l:relpath = trim(system(printf('realpath -s --relative-to=%s %s', shellescape(expand('%:p:h')), shellescape(l:path))))
    exe "normal! ci" . a:char . l:relpath
endfunction

function! MarkdownTools_RenameFilePath()
    let l:orig_path = expand('<cfile>')
    if !filereadable(l:orig_path) && !isdirectory(l:orig_path)
        echoerr "Not a valid file or directory: " . l:orig_path
        return
    endif
    let l:new_path = input('New path: ', l:orig_path, 'file')
    echo ' '
    if empty(l:new_path) || l:orig_path == l:new_path
        echo "Rename canceled."
        return
    endif
    let l:new_dir = fnamemodify(l:new_path, ':h')
    if !isdirectory(l:new_dir)
        call mkdir(l:new_dir, 'p')
    endif
    if rename(l:orig_path, l:new_path) == 0
        execute '%s#\V' . escape(l:orig_path, '/\.*$^~[]') . '#' . l:new_path . '#g'
        echo "Renamed successfully."
    else
        echoerr "Failed to rename file."
    endif
endfunction

function! s:CollectMatches(pattern, skip_http)
    set re=1
    let l:matches = []
    for lnum in range(1, line('$'))
        let line_text = getline(lnum)
        let start = 0
        while 1
            let match = matchstrpos(line_text, a:pattern, start)
            if empty(match[0]) | break | endif
            let match_text = match[0]
            let match_pos = match[1]
            let end_pos = match[2]
            if a:skip_http && match(match_text, '^https\?://') >= 0
                let start = end_pos
                continue
            endif
            call add(l:matches, {'filename': expand('%:p'), 'lnum': lnum, 'col': match_pos + 1, 'text': match_text})
            let start = end_pos
        endwhile
    endfor
    set re=0
    if empty(l:matches)
        echo "No matches found."
    else
        call setqflist(l:matches, 'r')
        copen
    endif
endfunction

function! MarkdownTools_FindWebsitesOnly()
    call s:CollectMatches('\vhttps?:\/\/[a-zA-Z0-9._~@%+=:,/?#&$!*\-]+', 0)
endfunction

function! MarkdownTools_FindFilepathsOnly()
    call s:CollectMatches('\v((\$[A-Z_][A-Z0-9_]*|~|\.{1,2})?\/)?([a-zA-Z0-9 ._@%+=:,~$!\-]+\/)+[a-zA-Z0-9 ._@%+=:,~$!\-]+\.[a-zA-Z0-9]+', 1)
endfunction

function! MarkdownTools_FindAllPathsAndWebsites()
    call s:CollectMatches('\v(https?:\/\/[a-zA-Z0-9._~@%+=:,/?#&$!*\-]+)|((\$[A-Z_][A-Z0-9_]*|~|\.{1,2})?\/)?([a-zA-Z0-9 ._@%+=:,~$!\-]+\/)+[a-zA-Z0-9 ._@%+=:,~$!\-]+\.[a-zA-Z0-9]+', 0)
endfunction

function! MarkdownTools_CaptureAndPasteImage()
    if expand('%:p') == ''
        echoerr "Please save the file first to determine the directory path!"
        return
    endif
    let l:current_dir = expand('%:p:h')
    let l:fig_dir = l:current_dir . '/figures'
    if !isdirectory(l:fig_dir) | call mkdir(l:fig_dir, 'p') | endif
    let l:filename = strftime('%Y%m%d_%H%M%S') . '.png'
    let l:filepath = l:fig_dir . '/' . l:filename
    let l:relpath = 'figures/' . l:filename
    call system('flameshot gui -r > ' . shellescape(l:filepath))
    if getfsize(l:filepath) > 0
        call inputsave()
        let l:width = input('Enter width (e.g., 50%, 400px, or blank for 100%): ')
        call inputrestore()
        let l:width = empty(l:width) ? '100%' : l:width
        execute "normal! a<img src=\"" . l:relpath . "\" width=\"" . l:width . "\" alt=\"Screenshot\">\n\<Esc>"
        redraw | echo "Screenshot captured!"
    else
        call system('rm ' . shellescape(l:filepath))
        redraw | echo "Screenshot canceled."
    endif
endfunction

function! MarkdownTools_MoveNote()
    update
    let l:old_file = expand('%:p')
    let l:old_dir = expand('%:p:h')
    let l:old_figures = l:old_dir . '/figures'
    call inputsave()
    let l:new_file = input('Move note to: ', l:old_file, 'file')
    call inputrestore()
    if l:new_file == '' || l:new_file == l:old_file
        redraw | echo "Move canceled." | return
    endif
    let l:new_file = fnamemodify(l:new_file, ':p')
    let l:new_dir = fnamemodify(l:new_file, ':p:h')
    let l:new_figures = l:new_dir . '/figures'
    if !isdirectory(l:new_dir) | call mkdir(l:new_dir, 'p') | endif
    call system('mv ' . shellescape(l:old_file) . ' ' . shellescape(l:new_file))
    if isdirectory(l:old_figures)
        if !isdirectory(l:new_figures)
            call system('mv ' . shellescape(l:old_figures) . ' ' . shellescape(l:new_figures))
        else
            call system('cp -n ' . shellescape(l:old_figures) . '/* ' . shellescape(l:new_figures) . '/ && rm -rf ' . shellescape(l:old_figures))
        endif
    endif
    execute 'edit ' . fnameescape(l:new_file)
    execute 'bwipeout ' . fnameescape(l:old_file)
    redraw | echo "Moved successfully to: " . l:new_dir
endfunction

" --- Autocommands & Filetype Specific Mappings ---

augroup MarkdownToolsPlugin

    autocmd!

    " Template insertion
    if g:md_tools_use_template
        autocmd BufNewFile *.md call s:InsertMarkdownTemplate()
    endif

    autocmd FileType markdown setlocal spell

    " Mappings specific to Markdown
    autocmd FileType markdown nnoremap <buffer> <leader>mo :exe '!'. g:md_tools_browser .' %:p &'<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mp :!marp % --html<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mP :exe '!'. g:md_tools_browser .' %:r.html &'<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>me :!pandoc % -f markdown -t html --data-dir=$HOME/.pandoc --template=bootstrap_menu.html -o %:r.html --metadata=title:%:t:r --toc<space>
    autocmd FileType markdown nnoremap <buffer> <leader>mE :exe '!'. g:md_tools_browser .' %:r.html &'<CR>

    " Insertions
    autocmd FileType markdown nnoremap <buffer> <leader>mi <Esc>i![this_is_an_image]()<Left>
    autocmd FileType markdown nnoremap <buffer> <leader>mI <Esc>i<img src="" title="" width="100%" height="100%"/><Esc>38<Left>i
    autocmd FileType markdown nnoremap <buffer> <leader>mV <Esc>i<video src="" title="" width="100%" height="100%" controls/><Esc>47<Left>i
    autocmd FileType markdown nnoremap <buffer> <leader>ml <Esc>i[this_is_a_link]()<Left>
    autocmd FileType markdown nnoremap <buffer> <leader>mb <Esc>i- [ ]
    autocmd FileType markdown nnoremap <buffer> <leader>mB <Esc>i```<CR>```<Up>
    autocmd FileType markdown nnoremap <buffer> <leader>mw <Esc>i::<Esc>i
    autocmd FileType markdown nnoremap <buffer> <leader>mc <Esc>i<span style="color:"><Esc>F<<Esc>19<Right>i
    autocmd FileType markdown nnoremap <buffer> <leader>mC <Esc>a</span><Esc>
    autocmd FileType markdown nnoremap <buffer> <leader>mT :execute('r ' . g:md_tools_table_template)<CR>
    autocmd FileType markdown nnoremap <buffer> <leader><bar> :<Esc>i[^]<Left>

    " Path Tools
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe" :call MarkdownTools_ToggleEnvPath('"')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe' :call MarkdownTools_ToggleEnvPath("'")<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe( :call MarkdownTools_ToggleEnvPath('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe) :call MarkdownTools_ToggleEnvPath('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe` :call MarkdownTools_ToggleEnvPath('`')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfew :call MarkdownTools_ToggleEnvPath('W')<CR>

    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa" :call MarkdownTools_ConvertRelativeToAbsolute('"')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa' :call MarkdownTools_ConvertRelativeToAbsolute("'")<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa( :call MarkdownTools_ConvertRelativeToAbsolute('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa) :call MarkdownTools_ConvertRelativeToAbsolute('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa` :call MarkdownTools_ConvertRelativeToAbsolute('`')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfaw :call MarkdownTools_ConvertRelativeToAbsolute('W')<CR>

    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr" :call MarkdownTools_ConvertAbsoluteToRelative('"')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr' :call MarkdownTools_ConvertAbsoluteToRelative("'")<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr( :call MarkdownTools_ConvertAbsoluteToRelative('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr) :call MarkdownTools_ConvertAbsoluteToRelative('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr` :call MarkdownTools_ConvertAbsoluteToRelative('`')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfrw :call MarkdownTools_ConvertAbsoluteToRelative('W')<CR>

    autocmd FileType markdown nnoremap <buffer> <leader>mfR :call MarkdownTools_RenameFilePath()<CR>
    autocmd FileType markdown vnoremap <buffer> <leader>mfR :<C-u>call MarkdownTools_RenameFilePath()<CR>

    " Search & Quickfix
    autocmd FileType markdown nnoremap <buffer> <leader>mfA :call MarkdownTools_FindAllPathsAndWebsites()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfw :call MarkdownTools_FindWebsitesOnly()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mff :call MarkdownTools_FindFilepathsOnly()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfh :lvimgrep /^#/ %<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfH :vimgrep /^#/ %<CR>

    " Note/Image management
    autocmd FileType markdown nnoremap <buffer> <leader>mfm :call MarkdownTools_MoveNote()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfp :call MarkdownTools_CaptureAndPasteImage()<CR>

augroup END
