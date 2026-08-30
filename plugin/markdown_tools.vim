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
    " 1. Identify target file under cursor or current buffer
    let l:target_file = expand('<cfile>')
    if empty(l:target_file) || (!filereadable(l:target_file) && !isdirectory(l:target_file))
        " Fallback to active buffer if cfile is not a valid file on disk
        let l:target_file = expand('%:p')
    else
        let l:target_file = fnamemodify(l:target_file, ':p')
    endif

    if empty(l:target_file) || !filereadable(l:target_file)
        echoerr "No valid note or media file selected."
        return
    endif

    " 2. Prompt for new target path
    call inputsave()
    let l:new_path = input('Rename target to: ', l:target_file, 'file')
    call inputrestore()
    echo ' '

    if empty(l:new_path) || l:target_file == l:new_path
        echo "Rename canceled."
        return
    endif

    let l:target_file = fnamemodify(l:target_file, ':p')
    let l:new_path = fnamemodify(l:new_path, ':p')
    let l:old_dir = fnamemodify(l:target_file, ':p:h')
    let l:new_dir = fnamemodify(l:new_path, ':p:h')

    " 3. Determine Vimwiki Root Directory
    let l:wiki_root = ''
    if exists('g:vimwiki_list') && !empty(g:vimwiki_list)
        let l:wiki_root = expand(g:vimwiki_list[0].path)
    else
        let l:index_file = findfile('index.md', l:old_dir . ';')
        let l:wiki_root = !empty(l:index_file) ? fnamemodify(l:index_file, ':p:h') : l:old_dir
    endif

    " 4. Create target folder and move physical file
    if !isdirectory(l:new_dir) | call mkdir(l:new_dir, 'p') | endif
    if rename(l:target_file, l:new_path) != 0
        echoerr "Failed to move/rename file on disk."
        return
    endif

    " 5. Scan and update all Markdown files referencing this media asset or note
    let l:wiki_files = glob(l:wiki_root . '/**/*.md', 0, 1)
    let l:old_filename = fnamemodify(l:target_file, ':t')
    let l:new_filename = fnamemodify(l:new_path, ':t')
    let l:updated_files_count = 0

    for l:file in l:wiki_files
        let l:file_abs = fnamemodify(l:file, ':p')
        if !filereadable(l:file_abs) | continue | endif

        let l:note_dir = fnamemodify(l:file_abs, ':p:h')
        let l:lines = readfile(l:file_abs)
        let l:modified = 0

        " Calculate relative paths from this specific Markdown file to old & new asset locations
        let l:old_rel_path = trim(system(printf('realpath -s --relative-to=%s %s', shellescape(l:note_dir), shellescape(l:target_file))))
        let l:new_rel_path = trim(system(printf('realpath -s --relative-to=%s %s', shellescape(l:note_dir), shellescape(l:new_path))))

        for l:idx in range(len(l:lines))
            let l:line = l:lines[l:idx]

            " Pattern A: Standard Markdown Image ![](...) or Link [](...)
            if l:line =~# escape(l:old_rel_path, '/\.*$^~[]') || l:line =~# escape(l:old_filename, '/\.*$^~[]')
                let l:line = substitute(l:line, '\V' . escape(l:old_rel_path, '/\.*$^~[]'), l:new_rel_path, 'g')
                let l:line = substitute(l:line, '\V' . escape(l:old_filename, '/\.*$^~[]'), l:new_rel_path, 'g')
                let l:lines[l:idx] = l:line
                let l:modified = 1
            endif

            " Pattern B: HTML <img src="..."> or <video src="..."> tags
            let l:html_src_pattern = '\v(src=["''])([^"''\>]+)(["''])'
            if l:line =~? 'src='
                let l:start = 0
                while 1
                    let l:match = matchstrpos(l:line, l:html_src_pattern, l:start)
                    if empty(l:match[0]) | break | endif

                    let l:src_val = matchlist(l:match[0], l:html_src_pattern)[2]
                    " Check if HTML src points to our target image
                    if fnamemodify(l:src_val, ':t') == l:old_filename || l:src_val == l:old_rel_path
                        let l:line = substitute(l:line, '\V' . escape(l:src_val, '/\.*$^~[]'), l:new_rel_path, 'g')
                        let l:lines[l:idx] = l:line
                        let l:modified = 1
                    endif
                    let l:start = l:match[2]
                endwhile
            endif
        endfor

        if l:modified
            call writefile(l:lines, l:file_abs)
            let l:updated_files_count += 1
        endif
    endfor

    " 6. Synchronize active Vim buffer if we renamed the current file
    if expand('%:p') == l:target_file
        execute 'edit ' . fnameescape(l:new_path)
        execute 'bwipeout ' . fnameescape(l:target_file)
    endif
    checktime

    redraw | echo printf("Target renamed successfully. Updated references across %d file(s).", l:updated_files_count)
endfunction

function! MarkdownTools_InsertWikiLink()
    " Determine Vimwiki Root Directory
    let l:wiki_root = ''
    if exists('g:vimwiki_list') && !empty(g:vimwiki_list)
        let l:wiki_root = expand(g:vimwiki_list[0].path)
    else
        let l:index_file = findfile('index.md', expand('%:p:h') . ';')
        let l:wiki_root = !empty(l:index_file) ? fnamemodify(l:index_file, ':p:h') : expand('%:p:h')
    endif

    let l:current_dir = expand('%:p:h')

    " Define callback handler when an item is selected in FZF
    function! s:OnWikiLinkSelected(selected) closure
        if empty(a:selected) | return | endif
        let l:target_abs = a:selected[0]

        " Calculate relative path from current note directory to selected note
        let l:rel_path = trim(system(printf('realpath -s --relative-to=%s %s', shellescape(l:current_dir), shellescape(l:target_abs))))
        let l:title = fnamemodify(l:target_abs, ':t:r')
        let l:link_text = printf('[%s](%s)', l:title, l:rel_path)

        " Insert link at cursor position
        execute "normal! a" . l:link_text
    endfunction

    " Configure FZF preview command (uses bat for syntax highlighting if available, else cat)
    let l:preview_cmd = executable('bat')
        \ ? 'bat --style=grid --color=always --line-range :50 {}'
        \ : 'cat {}'

    " Run FZF over all markdown files under wiki root
    call fzf#run(fzf#wrap({
        \ 'source':  globpath(l:wiki_root, '**/*.md', 0, 1),
        \ 'sink*':   function('s:OnWikiLinkSelected'),
        \ 'options': ['--prompt', 'Link Note> ', '--preview', l:preview_cmd, '--preview-window', 'right:60%'],
        \ 'down':    '40%'
        \ }))
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

    " 1. Extract all referenced figures in the buffer
    let l:related_figures = []
    for lnum in range(1, line('$'))
        let l:line_text = getline(lnum)
        let l:start = 0
        while 1
            let l:match = matchstrpos(l:line_text, 'figures\/[^ )"''\]>]\+', l:start)
            if empty(l:match[0]) | break | endif
            let l:fig_name = fnamemodify(l:match[0], ':t')
            call add(l:related_figures, l:fig_name)
            let l:start = l:match[2]
        endwhile
    endfor
    let l:related_figures = uniq(sort(l:related_figures))

    " 2. Copy only referenced figures to the new figures directory
    if isdirectory(l:old_figures) && !empty(l:related_figures)
        if !isdirectory(l:new_figures)
            call mkdir(l:new_figures, 'p')
        endif
        for l:fig in l:related_figures
            let l:src_fig = l:old_figures . '/' . l:fig
            let l:dst_fig = l:new_figures . '/' . l:fig
            if filereadable(l:src_fig) && !filereadable(l:dst_fig)
                let l:data = readfile(l:src_fig, 'b')
                call writefile(l:data, l:dst_fig, 'b')
            endif
        endfor
    endif

    " 3. Ensure target directory exists and move the Markdown note file
    if !isdirectory(l:new_dir) | call mkdir(l:new_dir, 'p') | endif
    call rename(l:old_file, l:new_file)

    " 4. Update Vim buffer references
    execute 'edit ' . fnameescape(l:new_file)
    execute 'bwipeout ' . fnameescape(l:old_file)
    redraw | echo "Moved successfully to: " . l:new_dir
endfunction

" Obsidian-Style Link & Backlink Discovery Tools for Vimwiki
function! MarkdownTools_FindBacklinks()
    let l:current_file = expand('%:p')
    if empty(l:current_file)
        echoerr "Please save or open a valid file first."
        return
    endif

    let l:filename = expand('%:t')
    let l:filename_no_ext = expand('%:t:r')

    " Determine Vimwiki root directory
    let l:wiki_root = ''
    if exists('g:vimwiki_list') && !empty(g:vimwiki_list)
        let l:wiki_root = expand(g:vimwiki_list[0].path)
    else
        let l:index_file = findfile('index.md', expand('%:p:h') . ';')
        let l:wiki_root = !empty(l:index_file) ? fnamemodify(l:index_file, ':p:h') : expand('%:p:h')
    endif

    " Get relative path from wiki root
    let l:rel_path = fnamemodify(l:current_file, ':.' )

    " Pattern matches: [text](filename.md), [text](rel/path.md), or [[filename]]
    let l:pattern = '\V\(' . escape(l:filename, '\') . '\|' . escape(l:rel_path, '\') . '\|\[\[' . escape(l:filename_no_ext, '\') . '\]\]\)'

    let l:wiki_files = glob(l:wiki_root . '/**/*.md', 0, 1)
    let l:matches = []

    for l:file in l:wiki_files
        " Skip self-referencing links within the current file
        if fnamemodify(l:file, ':p') == l:current_file
            continue
        endif

        if filereadable(l:file)
            let l:lines = readfile(l:file)
            for l:idx in range(len(l:lines))
                let l:line = l:lines[l:idx]
                if l:line =~# l:pattern
                    call add(l:matches, {
                        \ 'filename': l:file,
                        \ 'lnum': l:idx + 1,
                        \ 'text': trim(l:line)
                        \ })
                endif
            endfor
        endif
    endfor

    if empty(l:matches)
        redraw | echo "No backlinks found for: " . l:filename
    else
        call setqflist(l:matches, 'r')
        call setqflist([], 'r', {'title': 'Backlinks to ' . l:filename})
        copen
        redraw | echo printf("Found %d backlink(s).", len(l:matches))
    endif
endfunction

" Obsidian-Style Link & Backlink Discovery Tools for Vimwiki
function! MarkdownTools_FindOutlinks()
    let l:matches = []
    let l:current_file = expand('%:p')

    " Regex matches standard Markdown links [text](path) and Wiki links [[path]]
    let l:link_pattern = '\v\[[^\]]+\]\(([^)]+)\)|\[\[([^\]]+)\]\]'

    for l:lnum in range(1, line('$'))
        let l:line_text = getline(l:lnum)
        let l:start = 0
        while 1
            let l:match = matchstrpos(l:line_text, l:link_pattern, l:start)
            if empty(l:match[0]) | break | endif

            call add(l:matches, {
                \ 'filename': l:current_file,
                \ 'lnum': l:lnum,
                \ 'col': l:match[1] + 1,
                \ 'text': l:match[0]
                \ })
            let l:start = l:match[2]
        endwhile
    endfor

    if empty(l:matches)
        redraw | echo "No outgoing links found in this note."
    else
        call setqflist(l:matches, 'r')
        call setqflist([], 'r', {'title': 'Outgoing Links in ' . expand('%:t')})
        copen
        redraw | echo printf("Found %d outgoing link(s).", len(l:matches))
    endif
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
    autocmd FileType markdown nnoremap <buffer> <leader>mfI :call MarkdownTools_InsertWikiLink()<CR>

    " Obsidian-Style Link & Backlink Discovery Tools for Vimwiki
    autocmd FileType markdown nnoremap <buffer> <leader>mfb :call MarkdownTools_FindBacklinks()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfo :call MarkdownTools_FindOutlinks()<CR>

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
