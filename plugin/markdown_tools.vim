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
"
" ============================================================================
" Auto-load
" ============================================================================

function! s:MarkdownTools_LoadMarkdownTemplate() abort
    if line('$') == 1 && empty(getline(1))
        let l:template = g:md_tools_template_dir . 'markdown_template.md'
        if filereadable(l:template)
            exec '0r' l:template
            keeppatterns silent! %s/YYYY-mm-DD HH:MM:SS/\=strftime("%Y-%m-%d %T")/g
            keeppatterns silent! %s/YYYY-mm-DD/\=strftime("%Y-%m-%d")/g
        endif
    endif
endfunction

" ============================================================================
" Path
" ============================================================================

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

    " 5. Update Outlinks INSIDE the moved file
    if l:new_path =~? '\.md$' && filereadable(l:new_path)
        let l:moved_lines = readfile(l:new_path)
        let l:outlinks_modified = 0
        let l:outlink_patterns = ['\v\]\(([^)''"]+)\)', '\vsrc\=["'']([^"''\>]+)["'']']

        for l:idx in range(len(l:moved_lines))
            let l:line = l:moved_lines[l:idx]
            for l:pat in l:outlink_patterns
                let l:start = 0
                while 1
                    let l:match = matchstrpos(l:line, l:pat, l:start)
                    if empty(l:match[0]) | break | endif

                    let l:raw_link = matchlist(l:match[0], l:pat)[1]
                    " Ignore absolute paths, web URLs, and anchor links
                    if l:raw_link !~# '\v^(/|http[s]?://|#)'
                        let l:old_abs = simplify(l:old_dir . '/' . l:raw_link)
                        " Calculate new relative path based on the new directory
                        let l:new_rel = trim(system(printf('realpath -s --relative-to=%s %s', shellescape(l:new_dir), shellescape(l:old_abs))))

                        if l:raw_link !=# l:new_rel
                            let l:line = substitute(l:line, '\V' . escape(l:raw_link, '/\.*$^~[]'), escape(l:new_rel, '\&~'), 'g')
                            let l:outlinks_modified = 1
                        endif
                    endif
                    let l:start = l:match[2]
                endwhile
            endfor
            let l:moved_lines[l:idx] = l:line
        endfor

        if l:outlinks_modified
            call writefile(l:moved_lines, l:new_path)
        endif
    endif

    " 6. Scan and update backlinks across Vimwiki
    let l:wiki_files = glob(l:wiki_root . '/**/*.md', 0, 1)
    let l:old_filename = fnamemodify(l:target_file, ':t')
    let l:new_filename = fnamemodify(l:new_path, ':t')
    let l:updated_files_count = 0

    for l:file in l:wiki_files
        let l:file_abs = fnamemodify(l:file, ':p')
        " Skip the newly moved file to avoid double-processing
        if !filereadable(l:file_abs) || l:file_abs ==# l:new_path | continue | endif

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
                let l:line = substitute(l:line, '\V' . escape(l:old_rel_path, '/\.*$^~[]'), escape(l:new_rel_path, '\&~'), 'g')
                let l:line = substitute(l:line, '\V' . escape(l:old_filename, '/\.*$^~[]'), escape(l:new_rel_path, '\&~'), 'g')
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
                        let l:line = substitute(l:line, '\V' . escape(l:src_val, '/\.*$^~[]'), escape(l:new_rel_path, '\&~'), 'g')
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

    " 7. Synchronize active Vim buffer
    if expand('%:p') == l:target_file
        execute 'bwipeout! ' . fnameescape(l:target_file)
        execute 'edit ' . fnameescape(l:new_path)
    endif
    checktime

    redraw | echo printf("Target renamed successfully. Updated references across %d file(s).", l:updated_files_count)
endfunction

function! MarkdownTools_LocalizeResources(...)
    let l:target_dirs = a:0 > 0 ? a:000 : ['figures', 'assets', 'media', 'images']
    let l:current_file = expand('%:p')
    if empty(l:current_file) || !filereadable(l:current_file)
        echoerr "Please save the file first."
        return
    endif

    let l:current_dir = expand('%:p:h')
    let l:local_fig_dir = l:current_dir . '/figures'
    if !isdirectory(l:local_fig_dir)
        call mkdir(l:local_fig_dir, 'p')
    endif

    let l:lines = getline(1, '$')
    let l:modified = 0
    let l:copied_count = 0

    let l:dir_pattern = '\v[^ ()"''\]>]*(' . join(l:target_dirs, '|') . ')\/[^ )"''\]>]+'

    for l:idx in range(len(l:lines))
        let l:line = l:lines[l:idx]
        let l:start = 0

        while 1
            let l:match = matchstrpos(l:line, l:dir_pattern, l:start)
            if empty(l:match[0]) | break | endif

            " src_rel_path now correctly holds the full matched string (e.g., ../figures/image.png)
            let l:src_rel_path = l:match[0]
            let l:fig_name = fnamemodify(l:src_rel_path, ':t')

            " Resolve the actual absolute path to the file
            let l:src_abs_path = simplify(l:current_dir . '/' . l:src_rel_path)
            let l:dst_abs_path = l:local_fig_dir . '/' . l:fig_name
            let l:new_rel_path = 'figures/' . l:fig_name

            if filereadable(l:src_abs_path) && l:src_rel_path !=# l:new_rel_path
                if !filereadable(l:dst_abs_path)
                    let l:data = readfile(l:src_abs_path, 'b')
                    call writefile(l:data, l:dst_abs_path, 'b')
                    let l:copied_count += 1
                endif

                let l:line = substitute(l:line, '\V' . escape(l:src_rel_path, '/\.*$^~[]'), escape(l:new_rel_path, '\&~'), 'g')
                let l:lines[l:idx] = l:line
                let l:modified = 1
            endif

            let l:start = l:match[2]
        endwhile
    endfor

    if l:modified
        call setline(1, l:lines)
        update
        redraw | echo printf("Localized %d resource(s) into %s", l:copied_count, l:local_fig_dir)
    else
        redraw | echo "No external resources needed localization."
    endif
endfunction

" ============================================================================
" Link
" ============================================================================

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

" Open the file, PDF, or URL under the cursor using the system default app
function! MarkdownTools_OpenFileOrLink()
    let l:target = expand('<cfile>')
    if empty(l:target)
        echoerr "No file or link found under cursor."
        return
    endif
    " If it's not a web URL and not an absolute path, resolve it as a relative path
    if l:target !~# '^http[s]\?://' && l:target !~# '^/' && l:target !~# '^~'
        let l:target = expand('%:p:h') . '/' . l:target
    endif
    " Expand tilde if present (e.g., ~/Documents/...)
    if l:target =~# '^~'
        let l:target = fnamemodify(l:target, ':p')
    endif
    " Execute xdg-open asynchronously (Linux) or open (macOS)
    if executable('xdg-open')
        call system('xdg-open ' . shellescape(l:target) . ' &')
        redraw | echo "Opened: " . l:target
    elseif executable('open')
        call system('open ' . shellescape(l:target) . ' &')
        redraw | echo "Opened: " . l:target
    else
        echoerr "System open command (xdg-open / open) not found."
    endif
endfunction

" Paste an image directly from the system clipboard to ./figures
function! MarkdownTools_PasteClipboardImage()
    if expand('%:p') == ''
        echoerr "Please save the markdown file first to determine the directory path!"
        return
    endif
    let l:current_dir = expand('%:p:h')
    let l:fig_dir = l:current_dir . '/figures'
    if !isdirectory(l:fig_dir) | call mkdir(l:fig_dir, 'p') | endif
    let l:filename = 'clip_' . strftime('%Y%m%d_%H%M%S') . '.png'
    let l:filepath = l:fig_dir . '/' . l:filename
    let l:relpath = 'figures/' . l:filename
    " Determine the clipboard tool based on the user's OS / Display Server
    let l:cmd = ''
    if executable('wl-paste')
        " Wayland (Linux)
        let l:cmd = 'wl-paste --type image/png > ' . shellescape(l:filepath)
    elseif executable('xclip')
        " X11 (Linux)
        let l:cmd = 'xclip -selection clipboard -t image/png -o > ' . shellescape(l:filepath)
    elseif executable('pngpaste')
        " macOS (requires: brew install pngpaste)
        let l:cmd = 'pngpaste ' . shellescape(l:filepath)
    else
        echoerr "Clipboard tool missing. Install xclip, wl-paste, or pngpaste."
        return
    endif
    " Execute the paste command
    call system(l:cmd)
    " Verify if the image was actually saved (file size > 0)
    if getfsize(l:filepath) > 0
        " Insert the Markdown image syntax at the cursor
        execute "normal! a![](" . l:relpath . ")\<Esc>"
        redraw | echo "Clipboard image pasted to " . l:relpath
    else
        " Clean up the empty file if clipboard didn't contain an image
        call system('rm ' . shellescape(l:filepath))
        redraw | echo "No image found in system clipboard."
    endif
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

" Insert Link from Vimwiki
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
        \ }))
endfunction

" Convert HTML <img> tag on the current line to Markdown ![]() syntax
function! MarkdownTools_ConvertImgHtmlToMarkdown()
    let l:line = getline('.')
    " Pattern to match the entire <img ... > tag
    let l:img_pattern = '<img\s\+[^>]*>'
    let l:match = matchstr(l:line, l:img_pattern)
    if empty(l:match)
        echoerr "No HTML <img> tag found on the current line."
        return
    endif
    " Extract src, alt, and title attributes (handles both single and double quotes)
    let l:src = matchstr(l:match, 'src=["'']\zs[^"'']\+\ze["'']')
    let l:alt = matchstr(l:match, 'alt=["'']\zs[^"'']*\ze["'']')
    let l:title = matchstr(l:match, 'title=["'']\zs[^"'']*\ze["'']')
    if empty(l:src)
        echoerr "No 'src' attribute found in the <img> tag."
        return
    endif
    " If alt is empty but title exists, use the title as the [link name] fallback
    if empty(l:alt) && !empty(l:title)
        let l:alt = l:title
    endif
    " Construct the Markdown image string
    let l:md_img = '![' . l:alt . '](' . l:src
    " Append the title string if it exists
    if !empty(l:title)
        let l:md_img .= ' "' . l:title . '"'
    endif
    " Close the parentheses
    let l:md_img .= ')'
    " Escape the exact matched string for safe substitution
    let l:escaped_match = escape(l:match, '/\.*$^~[ ]')
    " Replace the first occurrence on the line
    let l:new_line = substitute(l:line, '\V' . l:escaped_match, escape(l:md_img, '\&~'), '')
    call setline('.', l:new_line)
    redraw | echo "Converted HTML image to Markdown syntax."
endfunction

" ============================================================================
" Collect Matches
" ============================================================================

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

function! MarkdownTools_LiveGrepVault()
    if !executable('rg')
        echoerr "ripgrep ('rg') is not installed or not in PATH."
        return
    endif

    " Determine Vimwiki Root Directory
    let l:wiki_root = ''
    if exists('g:vimwiki_list') && !empty(g:vimwiki_list)
        let l:wiki_root = expand(g:vimwiki_list[0].path)
    else
        let l:index_file = findfile('index.md', expand('%:p:h') . ';')
        let l:wiki_root = !empty(l:index_file) ? fnamemodify(l:index_file, ':p:h') : expand('%:p:h')
    endif

    if !isdirectory(l:wiki_root)
        echoerr "Wiki root directory does not exist: " . l:wiki_root
        return
    endif

    " Preview command setup
    let l:preview_cmd = executable('bat')
        \ ? 'bat --style=grid --color=always --highlight-line {2} {1}'
        \ : 'cat {1}'

    " Construct rg command targeting file CONTENTS only
    " '^' forces matching on line content start rather than path matching
    let l:rg_cmd = printf('rg --column --line-number --no-heading --color=always --smart-case --no-ignore --hidden -g "*.md" -e "^" %s', shellescape(l:wiki_root))

    " Multi-selection handler: iterates over all selected items
    function! s:OnGrepSelected(lines) closure
        if empty(a:lines) | return | endif

        " Open the first selected file in current window
        let l:first = split(a:lines[0], ':')
        if len(l:first) >= 2
            execute 'edit +' . l:first[1] . ' ' . fnameescape(l:first[0])
        endif

        " Open any additional selected files in background buffers
        for l:item in a:lines[1:]
            let l:parts = split(l:item, ':')
            if len(l:parts) >= 2
                execute 'badd +' . l:parts[1] . ' ' . fnameescape(l:parts[0])
            endif
        endfor
    endfunction

    " Run FZF using global g:fzf_layout rules with multi-select enabled
    call fzf#run(fzf#wrap('LiveGrepVault', {
        \ 'source':  l:rg_cmd,
        \ 'sink*':   function('s:OnGrepSelected'),
        \ 'options': ['-m', '--ansi', '--prompt', 'Vault Grep> ', '--delimiter', ':', '--preview', l:preview_cmd, '--preview-window', 'right:60%'],
        \ }))
endfunction

" ============================================================================
" Templates
" ============================================================================

" Function to read and insert the selected template
function! s:ReadSelectedTemplate(template_dict, template_name) abort
    let l:template_path = a:template_dict[a:template_name]
    let l:template_content = readfile(l:template_path)
    " Insert template content at cursor position
    call append(line('.') - 1, l:template_content)
endfunction

" Function to list and select templates using fzf
function! MarkdownTools_InsertMarkdownTemplate() abort
    " Check if template directory exists
    if !isdirectory(g:WIKI_TEMPLATE_DIR)
        echoerr "Template directory doesn't exist: " . g:WIKI_TEMPLATE_DIR
        return
    endif
    " Get list of template files
    let l:templates = split(globpath(g:WIKI_TEMPLATE_DIR, '*.md'), '\n')
    " Extract template names for display
    let l:template_names = map(copy(l:templates), 'fnamemodify(v:val, ":t:r")')
    " Create dictionary mapping display names to full paths
    let l:template_dict = {}
    let l:index = 0
    while l:index < len(l:templates)
        let l:template_dict[l:template_names[l:index]] = l:templates[l:index]
        let l:index += 1
    endwhile
    " Show selection menu using fzf
    call fzf#run({
        \ 'source': l:template_names,
        \ 'sink': function('s:ReadSelectedTemplate', [l:template_dict]),
        \ 'down': '25%'
        \ })
endfunction

" ============================================================================
" Export Functions
" ============================================================================

" Locate plugin root dynamically relative to this script
function! s:GetExportMd2PdfCmd()
    let l:input  = expand('%')
    let l:output = expand('%:r') . '.pdf'
    let l:config = s:plugin_root . '/assets/weasyprint/document.yaml'
    let l:img    = s:plugin_root . '/assets/html/raw-img.lua'
    let l:mermaid = s:plugin_root . '/assets/mermaid/mermaid-link.lua'
    return printf('!pandoc "%s" -o "%s" -f markdown -t pdf -d "%s" --lua-filter="%s" --lua-filter="%s"',
                \ l:input, l:output, l:config, l:img, l:mermaid, expand('%:t:r'))
endfunction

" ============================================================================
" --- Autocommands & Filetype Specific Mappings ---
" ============================================================================

augroup MarkdownToolsPlugin

    autocmd!

    " Template insertion (auto-load)
    if g:md_tools_use_template
        autocmd BufNewFile *.md call s:MarkdownTools_LoadMarkdownTemplate()
    endif

    " Setup spell checking
    autocmd FileType markdown setlocal spell

    " Insert template and update datetime
    autocmd FileType markdown nnoremap <buffer> <Leader>mfI :call MarkdownTools_InsertMarkdownTemplate()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfd <Esc>:keeppatterns %s/YYYY-mm-DD HH:MM:SS/\=strftime("%Y-%m-%d %T")/g<CR>:keeppatterns %s/YYYY-mm-DD/\=strftime("%Y-%m-%d")/g<CR>

    " Open files, links, markdown file (for preview)
    autocmd FileType markdown nnoremap <buffer> <leader>mo :call MarkdownTools_OpenFileOrLink()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mO :exe '!'. g:md_tools_browser .' %:p &'<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mP :exe '!'. g:md_tools_browser .' %:r.html &'<CR>

    " Export files (1: Marp MD -> HTML, 2: Pandoc MD -> HTML, 3: Pandoc MD -> PDF, 4: Libreoffice HTML -> DOCX)
    autocmd FileType markdown nnoremap <buffer> <leader>mfe1 :!marp % --html<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfe2 :!pandoc % -f markdown -t html --data-dir=$HOME/.pandoc --template=bootstrap_menu.html -o %:r.html --metadata=title:%:t:r --toc<space>
    autocmd FileType markdown nnoremap <buffer> <leader>mfe3 :<C-r>=<SID>GetExportMd2PdfCmd()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfe4 :!soffice --headless --infilter="HTML (StarWriter)" --convert-to "docx:MS Word 2007 XML" %:r.html<CR>

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
    autocmd FileType markdown nnoremap <buffer> <leader>mfi :call MarkdownTools_InsertWikiLink()<CR>

    " Path Tools (Env)
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe" :call MarkdownTools_ToggleEnvPath('"')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe' :call MarkdownTools_ToggleEnvPath("'")<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe( :call MarkdownTools_ToggleEnvPath('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe) :call MarkdownTools_ToggleEnvPath('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfe` :call MarkdownTools_ToggleEnvPath('`')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfew :call MarkdownTools_ToggleEnvPath('W')<CR>

    " Path Tools (Relative -> Absolute)
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa" :call MarkdownTools_ConvertRelativeToAbsolute('"')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa' :call MarkdownTools_ConvertRelativeToAbsolute("'")<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa( :call MarkdownTools_ConvertRelativeToAbsolute('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa) :call MarkdownTools_ConvertRelativeToAbsolute('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfa` :call MarkdownTools_ConvertRelativeToAbsolute('`')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfaw :call MarkdownTools_ConvertRelativeToAbsolute('W')<CR>

    " Path Tools (Absolute -> Relative)
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr" :call MarkdownTools_ConvertAbsoluteToRelative('"')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr' :call MarkdownTools_ConvertAbsoluteToRelative("'")<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr( :call MarkdownTools_ConvertAbsoluteToRelative('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr) :call MarkdownTools_ConvertAbsoluteToRelative('(')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfr` :call MarkdownTools_ConvertAbsoluteToRelative('`')<CR>
    autocmd FileType markdown nnoremap <buffer> <silent> <leader>mfrw :call MarkdownTools_ConvertAbsoluteToRelative('W')<CR>

    " Convert HTML image to Markdown image syntax on current line
    autocmd FileType markdown nnoremap <buffer> <leader>mfc :call MarkdownTools_ConvertImgHtmlToMarkdown()<CR>

    " File migration flow (file, link, resources)
    autocmd FileType markdown nnoremap <buffer> <leader>mfR :call MarkdownTools_RenameFilePath()<CR>
    autocmd FileType markdown vnoremap <buffer> <leader>mfR :<C-u>call MarkdownTools_RenameFilePath()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfL :call MarkdownTools_LocalizeResources()<CR>

    " Obsidian-Style Link & Backlink Discovery Tools for Vimwiki
    autocmd FileType markdown nnoremap <buffer> <leader>mfb :call MarkdownTools_FindBacklinks()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfo :call MarkdownTools_FindOutlinks()<CR>

    " Search & Quickfix
    autocmd FileType markdown nnoremap <buffer> <leader>mfg :call MarkdownTools_LiveGrepVault()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfA :call MarkdownTools_FindAllPathsAndWebsites()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfw :call MarkdownTools_FindWebsitesOnly()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mff :call MarkdownTools_FindFilepathsOnly()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfh :lvimgrep /^#/ %<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfH :vimgrep /^#/ %<CR>

    " Note/Image management
    autocmd FileType markdown nnoremap <buffer> <leader>mfp :call MarkdownTools_PasteClipboardImage()<CR>
    autocmd FileType markdown nnoremap <buffer> <leader>mfP :call MarkdownTools_CaptureAndPasteImage()<CR>

augroup END
