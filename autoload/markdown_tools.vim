" ==============================================================================
" Plugin:        vim-markdown-tools
" File:          autoload/markdown_tools.vim
" Description:   Core functions for Markdown Tools.
" Maintainer:    JordanWu1997 <jordankhwu@gmail.com>
" License:       MIT License
" ==============================================================================

" --- Template Insertion ---

function! markdown_tools#insert_template() abort
    if line('$') == 1 && empty(getline(1))
        let l:template = g:md_tools_template_dir . 'markdown_template.md'
        if filereadable(l:template)
            exec '0r' l:template
            let l:date_str = strftime("%Y-%m-%d %T")
            let l:author = get(g:, 'md_tools_author', '')
            let l:email = get(g:, 'md_tools_email', '')
            let l:title = expand('%:t:r')
            if empty(l:title) | let l:title = 'Title' | endif

            " Handle {{PLACEHOLDERS}}
            keeppatterns silent! %s/{{TITLE}}/\=l:title/ge
            keeppatterns silent! %s/{{AUTHOR}}/\=l:author/ge
            keeppatterns silent! %s/{{EMAIL}}/\=l:email/ge
            keeppatterns silent! %s/{{DATETIME}}/\=l:date_str/ge
            keeppatterns silent! %s/{{DATE}}/\=strftime("%Y-%m-%d")/ge

            " Legacy compatibility
            keeppatterns silent! %s/YYYY-mm-DD HH:MM:SS/\=l:date_str/ge
            if !empty(l:author)
                keeppatterns silent! %s/__Author:__ .*/\='__Author:__ ' . l:author/ge
            endif
            if !empty(l:email)
                keeppatterns silent! %s/__Contact:__ .*/\='__Contact:__ ' . l:email/ge
            endif
            keeppatterns silent! %s/^# Title$/\='# ' . l:title/ge
            1
        endif
    endif
endfunction

" --- Async Runner & Jobs ---

function! s:on_job_exit(code, desc, target_file, browser) abort
    if a:code == 0
        redraw
        echo "[MarkdownTools] " . a:desc . " completed successfully!"
        if !empty(a:target_file)
            call system(a:browser . ' ' . shellescape(a:target_file) . ' &')
        endif
    else
        redraw
        echoerr "[MarkdownTools] " . a:desc . " failed with exit code " . a:code
    endif
endfunction

function! s:run_async_command(cmd, desc, on_complete_browser) abort
    let l:browser = get(g:, 'md_tools_browser', $BROWSER)
    if empty(l:browser) | let l:browser = 'xdg-open' | endif

    if has('nvim')
        echo "Building " . a:desc . "..."
        call jobstart(a:cmd, {
            \ 'on_exit': {job_id, code, event -> s:on_job_exit(code, a:desc, a:on_complete_browser, l:browser)}
            \ })
    elseif has('job') && has('channel')
        echo "Building " . a:desc . "..."
        call job_start(a:cmd, {
            \ 'exit_cb': {job, code -> s:on_job_exit(code, a:desc, a:on_complete_browser, l:browser)}
            \ })
    else
        execute '!' . a:cmd
        if !empty(a:on_complete_browser)
            execute 'silent !' . l:browser . ' ' . shellescape(a:on_complete_browser) . ' &'
            redraw!
        endif
    endif
endfunction

" --- Preview & Export ---

function! markdown_tools#open_in_browser() abort
    let l:browser = get(g:, 'md_tools_browser', $BROWSER)
    if empty(l:browser) | let l:browser = 'xdg-open' | endif
    execute 'silent !' . l:browser . ' ' . shellescape(expand('%:p')) . ' &'
    redraw!
endfunction

function! markdown_tools#export_marp() abort
    let l:src = expand('%:p')
    let l:cmd = 'marp ' . shellescape(l:src) . ' --html'
    call s:run_async_command(l:cmd, 'Marp Presentation', '')
endfunction

function! markdown_tools#open_marp_html() abort
    let l:browser = get(g:, 'md_tools_browser', $BROWSER)
    if empty(l:browser) | let l:browser = 'xdg-open' | endif
    let l:target = expand('%:p:r') . '.html'
    execute 'silent !' . l:browser . ' ' . shellescape(l:target) . ' &'
    redraw!
endfunction

function! markdown_tools#export_pandoc() abort
    let l:src = expand('%:p')
    let l:out = expand('%:p:r') . '.html'
    let l:title = expand('%:t:r')
    let l:cmd = 'pandoc ' . shellescape(l:src) .
          \ ' -f markdown -t html --data-dir=$HOME/.pandoc --template=bootstrap_menu.html' .
          \ ' -o ' . shellescape(l:out) .
          \ ' --metadata=title:' . shellescape(l:title) . ' --toc'
    call s:run_async_command(l:cmd, 'Pandoc HTML', '')
endfunction

function! markdown_tools#open_pandoc_html() abort
    let l:browser = get(g:, 'md_tools_browser', $BROWSER)
    if empty(l:browser) | let l:browser = 'xdg-open' | endif
    let l:target = expand('%:p:r') . '.html'
    execute 'silent !' . l:browser . ' ' . shellescape(l:target) . ' &'
    redraw!
endfunction

function! markdown_tools#insert_table_template() abort
    let l:table_file = get(g:, 'md_tools_table_template', '')
    if filereadable(l:table_file)
        execute 'r ' . fnameescape(l:table_file)
    else
        echoerr "Table template file not found: " . l:table_file
    endif
endfunction

" --- Table Formatter ---

function! markdown_tools#format_table() abort
    let l:cur_line = line('.')
    let l:line_content = getline(l:cur_line)
    if l:line_content !~# '|'
        echo "Cursor is not on a Markdown table line."
        return
    endif

    let l:start_line = l:cur_line
    while l:start_line > 1 && getline(l:start_line - 1) =~# '^\s*|'
        let l:start_line -= 1
    endwhile

    let l:end_line = l:cur_line
    while l:end_line < line('$') && getline(l:end_line + 1) =~# '^\s*|'
        let l:end_line += 1
    endwhile

    let l:raw_lines = getline(l:start_line, l:end_line)
    if len(l:raw_lines) < 2
        echo "Table must have at least header and separator rows."
        return
    endif

    let l:rows = []
    let l:max_cols = 0

    for l:raw in l:raw_lines
        let l:trimmed = substitute(trim(l:raw), '^|\s*', '', '')
        let l:trimmed = substitute(l:trimmed, '\s*|$', '', '')
        let l:cells = split(l:trimmed, '\s*|\s*', 1)
        if len(l:cells) > l:max_cols
            let l:max_cols = len(l:cells)
        endif
        call add(l:rows, l:cells)
    endfor

    let l:delim_row_idx = -1
    for idx in range(len(l:rows))
        let l:is_delim = 1
        for cell in l:rows[idx]
            if cell !~# '^:*-+:*$' && !empty(cell)
                let l:is_delim = 0
                break
            endif
        endfor
        if l:is_delim && !empty(l:rows[idx])
            let l:delim_row_idx = idx
            break
        endif
    endfor

    let l:alignments = []
    for c in range(l:max_cols)
        let l:align = 0
        if l:delim_row_idx >= 0 && c < len(l:rows[l:delim_row_idx])
            let l:dcell = l:rows[l:delim_row_idx][c]
            if l:dcell =~# '^:.*:$'
                let l:align = 2
            elseif l:dcell =~# ':$'
                let l:align = 1
            endif
        endif
        call add(l:alignments, l:align)
    endfor

    let l:col_widths = repeat([3], l:max_cols)
    for r in range(len(l:rows))
        if r == l:delim_row_idx | continue | endif
        for c in range(len(l:rows[r]))
            let l:cell_len = strdisplaywidth(l:rows[r][c])
            if l:cell_len > l:col_widths[c]
                let l:col_widths[c] = l:cell_len
            endif
        endfor
    endfor

    let l:formatted_lines = []
    for r in range(len(l:rows))
        let l:row = l:rows[r]
        let l:formatted_cells = []
        if r == l:delim_row_idx
            for c in range(l:max_cols)
                let l:w = l:col_widths[c]
                if l:alignments[c] == 2
                    call add(l:formatted_cells, ':' . repeat('-', max([1, l:w - 2])) . ':')
                elseif l:alignments[c] == 1
                    call add(l:formatted_cells, repeat('-', max([1, l:w - 1])) . ':')
                else
                    call add(l:formatted_cells, repeat('-', l:w))
                endif
            endfor
        else
            for c in range(l:max_cols)
                let l:val = c < len(l:row) ? l:row[c] : ''
                let l:w = l:col_widths[c]
                let l:pad = l:w - strdisplaywidth(l:val)
                if l:alignments[c] == 1
                    call add(l:formatted_cells, repeat(' ', max([0, l:pad])) . l:val)
                elseif l:alignments[c] == 2
                    let l:left_pad = l:pad / 2
                    let l:right_pad = l:pad - l:left_pad
                    call add(l:formatted_cells, repeat(' ', max([0, l:left_pad])) . l:val . repeat(' ', max([0, l:right_pad])))
                else
                    call add(l:formatted_cells, l:val . repeat(' ', max([0, l:pad])))
                endif
            endfor
        endif
        call add(l:formatted_lines, '| ' . join(l:formatted_cells, ' | ') . ' |')
    endfor

    call setline(l:start_line, l:formatted_lines[0])
    if len(l:formatted_lines) > 1
        call setline(l:start_line + 1, l:formatted_lines[1:])
    endif
    echo "Table formatted (" . len(l:formatted_lines) . " rows, " . l:max_cols . " cols)."
endfunction

" --- Checkbox Cycling & Todo Discovery ---

function! markdown_tools#toggle_checkbox() abort
    let l:line = getline('.')
    let l:lnum = line('.')

    let l:task_regex = '^\(\s*[-*+]\s*\[\)\([ xXoO\-]\)\(\]\)'
    if l:line =~# l:task_regex
        let l:state = matchlist(l:line, l:task_regex)[2]
        let l:next_state = ' '
        if l:state ==# ' '
            let l:next_state = 'o'
        elseif l:state =~? 'o'
            let l:next_state = 'x'
        elseif l:state =~? 'x'
            let l:next_state = '-'
        elseif l:state ==# '-'
            let l:next_state = ' '
        endif
        let l:new_line = substitute(l:line, l:task_regex, '\1' . l:next_state . '\3', '')
        call setline(l:lnum, l:new_line)
        return
    endif

    let l:bullet_regex = '^\(\s*[-*+]\s*\)\(.*\)'
    if l:line =~# l:bullet_regex
        let l:new_line = substitute(l:line, l:bullet_regex, '\1[ ] \2', '')
        call setline(l:lnum, l:new_line)
        return
    endif

    let l:indent_regex = '^\(\s*\)\(.*\)'
    let l:new_line = substitute(l:line, l:indent_regex, '\1- [ ] \2', '')
    call setline(l:lnum, l:new_line)
endfunction

function! markdown_tools#find_todos() abort
    let l:matches = []
    let l:cur_file = expand('%:p')
    if empty(l:cur_file) | return | endif

    for lnum in range(1, line('$'))
        let l:line = getline(lnum)
        if l:line =~# '^\s*[-*+]\s*\[[ oO]\]'
            call add(l:matches, {
                \ 'filename': l:cur_file,
                \ 'lnum': lnum,
                \ 'col': 1,
                \ 'text': trim(l:line)
                \ })
        endif
    endfor

    if empty(l:matches)
        echo "No pending TODOs found in current note!"
    else
        call setqflist(l:matches, 'r')
        call setqflist([], 'a', {'title': 'TODOs in ' . expand('%:t')})
        copen
        echo "Found " . len(l:matches) . " pending TODO(s)."
    endif
endfunction

" --- Table of Contents (TOC) ---

function! s:slugify(text) abort
    let l:slug = tolower(a:text)
    let l:slug = substitute(l:slug, '\[\([^\]]*\)\]([^)]*)', '\1', 'g')
    let l:slug = substitute(l:slug, '`\([^`]*\)`', '\1', 'g')
    let l:slug = substitute(l:slug, '[^a-z0-9 _\-]', '', 'g')
    let l:slug = substitute(l:slug, '\s\+', '-', 'g')
    let l:slug = substitute(l:slug, '-\+', '-', 'g')
    let l:slug = substitute(l:slug, '^-', '', '')
    let l:slug = substitute(l:slug, '-$', '', '')
    return l:slug
endfunction

function! markdown_tools#generate_toc() abort
    let l:toc_lines = ['<!-- TOC -->']
    let l:in_code_block = 0
    let l:min_level = 99
    let l:headers = []
    let l:seen_slugs = {}

    for lnum in range(1, line('$'))
        let l:line = getline(lnum)
        if l:line =~# '^```'
            let l:in_code_block = !l:in_code_block
            continue
        endif
        if l:in_code_block | continue | endif

        if l:line =~# '^#\+\s\+'
            let l:hashes = matchstr(l:line, '^#\+')
            let l:level = len(l:hashes)
            let l:title = trim(substitute(l:line, '^#\+\s\+', '', ''))
            if empty(l:title) | continue | endif
            if l:level < l:min_level | let l:min_level = l:level | endif
            call add(l:headers, {'level': l:level, 'title': l:title})
        endif
    endfor

    if empty(l:headers)
        echo "No Markdown headings found to generate TOC."
        return
    endif

    for h in l:headers
        let l:indent = repeat('  ', max([0, h.level - l:min_level]))
        let l:base_slug = s:slugify(h.title)
        if empty(l:base_slug) | let l:base_slug = 'section' | endif

        if has_key(l:seen_slugs, l:base_slug)
            let l:seen_slugs[l:base_slug] += 1
            let l:slug = l:base_slug . '-' . l:seen_slugs[l:base_slug]
        else
            let l:seen_slugs[l:base_slug] = 0
            let l:slug = l:base_slug
        endif

        call add(l:toc_lines, l:indent . '- [' . h.title . '](#' . l:slug . ')')
    endfor
    call add(l:toc_lines, '<!-- /TOC -->')

    let l:toc_start = -1
    let l:toc_end = -1
    for lnum in range(1, line('$'))
        if getline(lnum) =~# '<!--\s*TOC\s*-->'
            let l:toc_start = lnum
        elseif l:toc_start > 0 && getline(lnum) =~# '<!--\s*/TOC\s*-->'
            let l:toc_end = lnum
            break
        endif
    endfor

    if l:toc_start > 0 && l:toc_end >= l:toc_start
        execute l:toc_start . ',' . l:toc_end . 'delete _'
        call append(l:toc_start - 1, l:toc_lines)
        echo "Updated existing Table of Contents (" . len(l:headers) . " headings)."
    else
        let l:cur_line = line('.')
        call append(l:cur_line, l:toc_lines)
        echo "Inserted Table of Contents (" . len(l:headers) . " headings)."
    endif
endfunction

" --- Path Management ---

function! markdown_tools#toggle_env_path(char) abort
    let l:word = expand('<cfile>')
    let l:home = $HOME
    if l:word =~? '^\$HOME\>'
        let l:subpath = substitute(l:word, '^\$HOME', '', '')
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

function! markdown_tools#convert_rel_to_abs(char) abort
    let l:path = expand('<cfile>:p')
    let l:absolute = trim(system(printf('realpath %s', shellescape(l:path))))
    execute "normal! ci" . a:char . l:absolute
endfunction

function! markdown_tools#convert_abs_to_rel(char) abort
    let l:path = expand('<cfile>')
    let l:relpath = trim(system(printf('realpath -s --relative-to=%s %s',
          \ shellescape(expand('%:p:h')), shellescape(l:path))))
    execute "normal! ci" . a:char . l:relpath
endfunction

function! markdown_tools#rename_file_path() abort
    let l:orig_path = expand('<cfile>')
    if !filereadable(l:orig_path) && !isdirectory(l:orig_path)
        echoerr "Not a valid file or directory: " . l:orig_path
        return
    endif
    let l:new_path = input('New path: ', l:orig_path, 'file')
    echo ' '
    if empty(l:new_path) || l:orig_path ==# l:new_path
        echo "Rename canceled."
        return
    endif
    let l:new_dir = fnamemodify(l:new_path, ':h')
    if !isdirectory(l:new_dir)
        call mkdir(l:new_dir, 'p')
    endif
    if rename(l:orig_path, l:new_path) == 0
        execute '%s#\V' . escape(l:orig_path, '\#') . '#' . escape(l:new_path, '\#') . '#ge'
        echo "Renamed successfully."
    else
        echoerr "Failed to rename file."
    endif
endfunction

" --- Search Tools (Quickfix) ---

function! s:collect_matches(pattern, skip_http) abort
    let l:save_re = &regexpengine
    let l:matches = []
    try
        let &regexpengine = 1
        for lnum in range(1, line('$'))
            let l:line_text = getline(lnum)
            let l:start = 0
            while 1
                let l:match = matchstrpos(l:line_text, a:pattern, l:start)
                if empty(l:match[0]) | break | endif
                let l:match_text = l:match[0]
                let l:match_pos = l:match[1]
                let l:end_pos = l:match[2]
                if a:skip_http && match(l:match_text, '^https\?://') >= 0
                    let l:start = l:end_pos
                    continue
                endif
                call add(l:matches, {
                    \ 'filename': expand('%:p'),
                    \ 'lnum': lnum,
                    \ 'col': l:match_pos + 1,
                    \ 'text': l:match_text
                    \ })
                let l:start = l:end_pos
            endwhile
        endfor
    finally
        let &regexpengine = l:save_re
    endtry

    if empty(l:matches)
        echo "No matches found."
    else
        call setqflist(l:matches, 'r')
        copen
    endif
endfunction

function! markdown_tools#find_websites_only() abort
    call s:collect_matches('\vhttps?:\/\/[a-zA-Z0-9._~@%+=:,/?#&$!*\-]+', 0)
endfunction

function! markdown_tools#find_filepaths_only() abort
    call s:collect_matches('\v((\$[A-Z_][A-Z0-9_]*|~|\.{1,2})?\/)?([a-zA-Z0-9 ._@%+=:,~$!\-]+\/)+[a-zA-Z0-9 ._@%+=:,~$!\-]+\.[a-zA-Z0-9]+', 1)
endfunction

function! markdown_tools#find_all_paths_and_websites() abort
    call s:collect_matches('\v(https?:\/\/[a-zA-Z0-9._~@%+=:,/?#&$!*\-]+)|((\$[A-Z_][A-Z0-9_]*|~|\.{1,2})?\/)?([a-zA-Z0-9 ._@%+=:,~$!\-]+\/)+[a-zA-Z0-9 ._@%+=:,~$!\-]+\.[a-zA-Z0-9]+', 0)
endfunction

" --- Asset & Note Management ---

function! markdown_tools#capture_and_paste_image() abort
    if empty(expand('%:p'))
        echoerr "Please save the file first to determine the directory path!"
        return
    endif
    let l:current_dir = expand('%:p:h')
    let l:fig_dir = l:current_dir . '/figures'
    if !isdirectory(l:fig_dir) | call mkdir(l:fig_dir, 'p') | endif
    let l:filename = strftime('%Y%m%d_%H%M%S') . '.png'
    let l:filepath = l:fig_dir . '/' . l:filename
    let l:relpath = 'figures/' . l:filename

    if executable('flameshot')
        call system('flameshot gui -r > ' . shellescape(l:filepath))
    elseif executable('grim') && executable('slurp')
        call system('grim -g "$(slurp)" ' . shellescape(l:filepath))
    elseif executable('screencapture')
        call system('screencapture -i ' . shellescape(l:filepath))
    elseif executable('maim')
        call system('maim -s ' . shellescape(l:filepath))
    else
        echoerr "No supported screenshot tool found (flameshot, grim+slurp, screencapture, maim)."
        return
    endif

    if getfsize(l:filepath) > 0
        call inputsave()
        let l:width = input('Enter width (e.g., 50%, 400px, or blank for 100%): ')
        call inputrestore()
        let l:width = empty(l:width) ? '100%' : l:width
        execute "normal! a<img src=\"" . l:relpath . "\" width=\"" . l:width . "\" alt=\"Screenshot\">\n\<Esc>"
        redraw | echo "Screenshot captured!"
    else
        call delete(l:filepath)
        redraw | echo "Screenshot canceled."
    endif
endfunction

function! markdown_tools#paste_from_clipboard() abort
    if empty(expand('%:p'))
        echoerr "Please save the file first to determine the directory path!"
        return
    endif
    let l:current_dir = expand('%:p:h')
    let l:fig_dir = l:current_dir . '/figures'
    if !isdirectory(l:fig_dir) | call mkdir(l:fig_dir, 'p') | endif
    let l:filename = strftime('%Y%m%d_%H%M%S') . '.png'
    let l:filepath = l:fig_dir . '/' . l:filename
    let l:relpath = 'figures/' . l:filename

    if executable('wl-paste')
        call system('wl-paste --type image/png > ' . shellescape(l:filepath))
    elseif executable('xclip')
        call system('xclip -selection clipboard -t image/png -o > ' . shellescape(l:filepath))
    elseif executable('pngpaste')
        call system('pngpaste ' . shellescape(l:filepath))
    else
        echoerr "No clipboard image tool found (xclip, wl-paste, or pngpaste required)."
        return
    endif

    if getfsize(l:filepath) > 0
        call inputsave()
        let l:width = input('Enter width (e.g., 50%, 400px, or blank for 100%): ')
        call inputrestore()
        let l:width = empty(l:width) ? '100%' : l:width
        execute "normal! a<img src=\"" . l:relpath . "\" width=\"" . l:width . "\" alt=\"Screenshot\">\n\<Esc>"
        redraw | echo "Screenshot pasted from clipboard!"
    else
        call delete(l:filepath)
        redraw | echo "No valid image found in clipboard."
    endif
endfunction

function! markdown_tools#move_note() abort
    update
    let l:old_file = expand('%:p')
    let l:old_dir = expand('%:p:h')
    let l:old_figures = l:old_dir . '/figures'
    call inputsave()
    let l:new_file = input('Move note to: ', l:old_file, 'file')
    call inputrestore()
    if empty(l:new_file) || l:new_file ==# l:old_file
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

" --- Backlink & Inbound Reference Discovery ---

function! markdown_tools#find_backlinks() abort
    let l:cur_file = expand('%:p')
    if empty(l:cur_file)
        echoerr "Buffer must be saved to a file to find backlinks."
        return
    endif

    let l:filename = expand('%:t')
    let l:basename = expand('%:t:r')
    let l:cur_dir = expand('%:p:h')
    let l:search_dir = get(g:, 'md_tools_search_dir', '')
    if empty(l:search_dir)
        let l:git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
        if v:shell_error == 0 && !empty(l:git_root) && isdirectory(l:git_root)
            let l:search_dir = l:git_root
        else
            let l:search_dir = l:cur_dir
        endif
    endif

    let l:matches = []

    if executable('rg')
        let l:pattern = escape(l:filename, '[]()/\.^$*+?{}|') . '|\[\[\s*' . escape(l:basename, '[]()/\.^$*+?{}|') . '(\]\]|\|)'
        let l:cmd = 'rg --vimgrep --no-heading --color=never -g "*.md" -g "*.markdown" -g "*.wiki" -e ' . shellescape(l:pattern) . ' ' . shellescape(l:search_dir)
        let l:lines = split(system(l:cmd), "\n")
        for line in l:lines
            let l:parts = split(line, ':')
            if len(l:parts) >= 4
                let l:m_file = l:parts[0]
                let l:m_lnum = str2nr(l:parts[1])
                let l:m_col  = str2nr(l:parts[2])
                let l:m_text = join(l:parts[3:], ':')
                if fnamemodify(l:m_file, ':p') !=# l:cur_file
                    call add(l:matches, {
                        \ 'filename': fnamemodify(l:m_file, ':p'),
                        \ 'lnum': l:m_lnum,
                        \ 'col': l:m_col,
                        \ 'text': trim(l:m_text)
                        \ })
                endif
            endif
        endfor
    else
        let l:files = globpath(l:search_dir, '**/*.{md,markdown,wiki}', 0, 1)
        for f in l:files
            if fnamemodify(f, ':p') ==# l:cur_file | continue | endif
            let l:flines = readfile(f)
            for idx in range(len(l:flines))
                let l:line = l:flines[idx]
                if l:line =~# escape(l:filename, '\') || l:line =~# '\[\[' . escape(l:basename, '\')
                    call add(l:matches, {
                        \ 'filename': f,
                        \ 'lnum': idx + 1,
                        \ 'col': 1,
                        \ 'text': trim(l:line)
                        \ })
                endif
            endfor
        endfor
    endif

    if empty(l:matches)
        echo "No backlinks found for: " . l:filename
    else
        call setqflist(l:matches, 'r')
        call setqflist([], 'a', {'title': 'Backlinks -> ' . l:filename})
        copen
        echo "Found " . len(l:matches) . " backlink(s) to " . l:filename
    endif
endfunction

" --- Dead Link Finder ---

function! markdown_tools#find_dead_links() abort
    let l:cur_file = expand('%:p')
    if empty(l:cur_file)
        echoerr "Buffer must be saved to a file."
        return
    endif
    let l:cur_dir = expand('%:p:h')
    let l:dead_links = []
    let l:link_regex = '\v(!?\[[^\]]*\]\(([^)]+)\)|<(img|video|source|a)\s+[^>]*(src|href)\=["'']([^"'']+)["''])'

    for lnum in range(1, line('$'))
        let l:line = getline(lnum)
        let l:start = 0
        while 1
            let l:m = matchstrpos(l:line, l:link_regex, l:start)
            if empty(l:m[0]) | break | endif
            let l:raw_match = l:m[0]
            let l:pos = l:m[1]
            let l:end = l:m[2]
            let l:start = l:end

            let l:target = ''
            if l:raw_match =~# '^!?\['
                let l:target = matchstr(l:raw_match, '\v\(([^)]+)\)')
                let l:target = substitute(l:target, '^\((.*)\)$', '\1', '')
                let l:target = substitute(l:target, '^[<\(]\s*', '', '')
                let l:target = substitute(l:target, '\s*[>\)]$', '', '')
                let l:target = split(l:target, '\s\+["'']')[0]
            else
                let l:target = matchstr(l:raw_match, '\v(src|href)\=["'']([^"'']+)["'']')
                let l:target = substitute(l:target, '\v^(src|href)\=["'']|["'']$', '', 'g')
            endif

            let l:target = trim(l:target)
            if empty(l:target) || l:target =~? '^(https\?://|ftp://|mailto:|#|data:|javascript:)'
                continue
            endif

            let l:clean_target = split(l:target, '[#?]')[0]
            if empty(l:clean_target) | continue | endif

            if l:clean_target =~? '^\$HOME\>'
                let l:resolved = $HOME . substitute(l:clean_target, '^\$HOME', '', '')
            elseif l:clean_target =~? '^~'
                let l:resolved = expand(l:clean_target)
            elseif l:clean_target =~? '^/'
                let l:resolved = l:clean_target
            else
                let l:resolved = l:cur_dir . '/' . l:clean_target
            endif
            let l:resolved = fnamemodify(l:resolved, ':p')

            if !filereadable(l:resolved) && !isdirectory(l:resolved)
                call add(l:dead_links, {
                    \ 'filename': l:cur_file,
                    \ 'lnum': lnum,
                    \ 'col': l:pos + 1,
                    \ 'text': '[Dead Link] ' . l:target . ' (File not found)'
                    \ })
            endif
        endwhile
    endfor

    if empty(l:dead_links)
        echo "No dead links found! All local references are valid."
    else
        call setqflist(l:dead_links, 'r')
        call setqflist([], 'a', {'title': 'Dead Links in ' . expand('%:t')})
        copen
        echo "Found " . len(l:dead_links) . " dead link(s)."
    endif
endfunction

" --- Multi-Note Aware Orphan Figure Cleaner ---

function! s:get_referenced_figures(scope_dir) abort
    let l:md_files = globpath(a:scope_dir, '**/*.{md,markdown,wiki}', 0, 1)
    let l:refs = {}

    for f in l:md_files
        let l:lines = readfile(f)
        for line in l:lines
            let l:start = 0
            while 1
                let l:m = matchstrpos(line, '\v([a-zA-Z0-9_.\-\/]+\.(png|jpg|jpeg|gif|svg|webp|bmp|mp4|mov|webm|pdf))', l:start)
                if empty(l:m[0]) | break | endif
                let l:img = l:m[0]
                let l:base = fnamemodify(l:img, ':t')
                let l:refs[l:img] = 1
                let l:refs[l:base] = 1
                let l:refs['figures/' . l:base] = 1
                let l:refs['./figures/' . l:base] = 1
                let l:start = l:m[2]
            endwhile
        endfor
    endfor
    return {'refs': l:refs, 'count': len(l:md_files)}
endfunction

function! markdown_tools#find_orphan_figures() abort
    let l:cur_dir = expand('%:p:h')
    let l:fig_dir = l:cur_dir . '/figures'
    if !isdirectory(l:fig_dir)
        echo "No './figures' directory found in " . l:cur_dir
        return []
    endif

    let l:scan = s:get_referenced_figures(l:cur_dir)
    let l:refs = l:scan.refs
    let l:md_count = l:scan.count

    let l:actual_files = glob(l:fig_dir . '/*', 0, 1)
    let l:orphans = []

    for f in l:actual_files
        if isdirectory(f) | continue | endif
        let l:fname = fnamemodify(f, ':t')
        if l:fname =~# '^\.' | continue | endif

        if !has_key(l:refs, l:fname) && !has_key(l:refs, 'figures/' . l:fname)
            call add(l:orphans, {
                \ 'filename': f,
                \ 'lnum': 1,
                \ 'col': 1,
                \ 'text': '[Orphan Figure] ' . l:fname . ' (Not referenced in ' . l:md_count . ' note(s))'
                \ })
        endif
    endfor

    if empty(l:orphans)
        echo "No orphan figures found! All figures are referenced across " . l:md_count . " note(s)."
    else
        call setqflist(l:orphans, 'r')
        call setqflist([], 'a', {'title': 'Orphan Figures in ./figures (' . l:md_count . ' notes scanned)'})
        copen
        echo "Found " . len(l:orphans) . " orphan figure(s) across " . l:md_count . " note(s)."
    endif
    return l:orphans
endfunction

function! markdown_tools#clean_orphan_figures() abort
    let l:cur_dir = expand('%:p:h')
    let l:fig_dir = l:cur_dir . '/figures'
    if !isdirectory(l:fig_dir)
        echo "No './figures' directory found in " . l:cur_dir
        return
    endif

    let l:scan = s:get_referenced_figures(l:cur_dir)
    let l:refs = l:scan.refs
    let l:md_count = l:scan.count

    let l:actual_files = glob(l:fig_dir . '/*', 0, 1)
    let l:orphan_files = []

    for f in l:actual_files
        if isdirectory(f) | continue | endif
        let l:fname = fnamemodify(f, ':t')
        if l:fname =~# '^\.' | continue | endif
        if !has_key(l:refs, l:fname) && !has_key(l:refs, 'figures/' . l:fname)
            call add(l:orphan_files, f)
        endif
    endfor

    if empty(l:orphan_files)
        echo "No orphan figures found across " . l:md_count . " note(s). Nothing to clean!"
        return
    endif

    echo "Found " . len(l:orphan_files) . " orphan figure(s) across " . l:md_count . " note(s):"
    for ofile in l:orphan_files
        echo "  - " . fnamemodify(ofile, ':t')
    endfor

    let l:choice = confirm(
        \ "How would you like to handle these orphan figures?\n(Safe Move archives them to ./figures/.trash/)",
        \ "&1 Move to ./figures/.trash/\n&2 Permanently Delete\n&3 View in Quickfix\n&4 Cancel",
        \ 1)

    if l:choice == 1
        let l:trash_dir = l:fig_dir . '/.trash'
        if !isdirectory(l:trash_dir) | call mkdir(l:trash_dir, 'p') | endif
        for ofile in l:orphan_files
            call rename(ofile, l:trash_dir . '/' . fnamemodify(ofile, ':t'))
        endfor
        echo "Moved " . len(l:orphan_files) . " orphan figure(s) to " . l:trash_dir
    elseif l:choice == 2
        for ofile in l:orphan_files
            call delete(ofile)
        endfor
        echo "Deleted " . len(l:orphan_files) . " orphan figure(s)."
    elseif l:choice == 3
        call markdown_tools#find_orphan_figures()
    else
        echo "Canceled."
    endif
endfunction
