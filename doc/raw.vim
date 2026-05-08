````vim
" Markdown -------------------------------------------------------------------

let USING_NEOVIM = has('nvim')
let USING_VIM = !USING_NEOVIM
let USING_GUI_SOFTWARE = 1
" Web browser for markdown preview
let s:WEBBROWSER = $BROWSER

" Markdown Template file
let s:MARKDOWN_TEMPLATE = s:TEMPLATE_DIR . 'markdown_template.md'
" Markdown Table template (in HTML)
let g:MARKDOWN_TABLE_TEMPLATE = s:TEMPLATE_DIR . 'table.html'

" Set spell check for markdown files
autocmd BufEnter *.md setlocal spell
" Markdown previewer [no extra vim plugin needed]
" From https://krehwell.com/blog/Open Markdown Previewer Through Vim
" Google-chrome extension is needed for markdown viewer
if USING_GUI_SOFTWARE && !USING_VIM8
    let $OPENBROWSER = 'noremap <leader><F4> :!'. s:WEBBROWSER .' %:p &<CR>'
    autocmd BufEnter *.md echom '[Press Space+F4 to Preview .md File]'
    autocmd BufEnter *.md exe $OPENBROWSER
endif
" Synchronous markdown previewer (markdown-preview plugin)
if USING_GUI_SOFTWARE && USING_VIM8
    " Web browser used to preview
    let g:mkdp_browser = s:WEBBROWSER
    " Close browser after markdown file is close
    let g:mkdp_auto_close = 0
    " Show url of markdown previewer
    let g:mkdp_echo_preview_url = 1
    autocmd BufEnter *.md echom '[Press Space+F4 to Preview .md File]'
    autocmd BufEnter *.md nmap <leader><F4> <Plug>MarkdownPreviewToggle<CR>
    autocmd BufEnter *.md setlocal scrolloff=999
endif
" Open current file directly with web-browser
let $OPENBROWSER = 'noremap <leader>mo :!'. s:WEBBROWSER .' %:p &<CR>'
autocmd BufEnter *.md exe $OPENBROWSER
" MARP: markdown presentation ecosystem (https://marp.app/)
autocmd BufEnter *.md noremap <leader>mp <Esc>:!marp % --html<CR>
let $MARPOPENHTMLBROWSER = 'noremap <leader>mP :!'. s:WEBBROWSER .' %:r.html &<CR>'
autocmd BufEnter *.md exe $MARPOPENHTMLBROWSER
" Load template file when new file created
function! s:InsertMarkdownTemplate() abort
    " Check if the buffer is empty and is a new file since
    if line('$') == 1 && empty(getline(1))
        " Read the skeleton content from your variable/file
        exec '0r' s:MARKDOWN_TEMPLATE
        " Update the timestamp
        keeppatterns silent! %s/YYYY-mm-DD HH:MM:SS/=strftime("%Y-%m-%d %T")/g
    endif
endfunction
if USING_MARKDOWN_TEMPLATE
    autocmd BufNewFile *.md call s:InsertMarkdownTemplate()
endif
" Pandoc: export markdown file as html
" -- To pack resources e.g. image to single HTML file
"    -- For newer pandoc, add --standalone --embed-resources
"    -- For older pandoc, add --self-contained
" -- Template: https://github.com/ryangrose/easy-pandoc-templates
autocmd BufEnter *.md noremap <leader>me
         <Esc>:!pandoc % -f markdown -t html
         --data-dir=$HOME/.pandoc
         --template=bootstrap_menu.html
         -o %:r.html --metadata=title:%:t:r --toc<space>
let $PANDOCOPENHTMLBROWSER = 'noremap <leader>mE :!'. s:WEBBROWSER .' %:r.html &<CR>'
autocmd BufEnter *.md exe $PANDOCOPENHTMLBROWSER
" Insert image
noremap <leader>mi <Esc>i![this_is_an_image]()<Left>
noremap <leader>mI <Esc>i<img src="" title="" width="100%" height="100%"/><Esc>38<Left>i
" Insert video in markdown file
noremap <leader>mV <Esc>i<video src="" title="" width="100%" height="100%" controls/><Esc>47<Left>i
" Insert link
noremap <leader>ml <Esc>i[this_is_a_link]()<Left>
" Insert checkbox (also included in VimwikiToggleListItem)
noremap <leader>mb <Esc>i-<space>[ ]<space>
" Insert code block
noremap <leader>mB <Esc>i```<CR>```<Up>
" Insert tag (Vimwiki-favored)
noremap <leader>mw <Esc>i::<Esc>i
" Insert HTML style color tag
noremap <leader>mc <Esc>i<span style="color:"><Esc>F<<Esc>19<Right>i
noremap <leader>mC <Esc>a</span><Esc>
" Insert HTML table template
noremap <leader>mT <Esc>:execute('r'.g:MARKDOWN_TABLE_TEMPLATE)<CR>
" File/Link tools:
" -- For
"    -- Convert absolute paths between home directory and $HOME
"    -- Convert file path between absolute path and relative path
"    -- Rename file path and move file to the new file path
"    -- Rename file path, move file, and update all links that contains the file
"    -- Find all headers in current buffer and send them to location/quickfix list
"    -- Find all files/URLs in current buffer and send them to quickfix list
" Toggle env variable expansion
function! ToggleEnvPath(char)
    let l:word = expand('<cfile>')
    let l:home = $HOME
    " Expand $HOME to absolute path
    if l:word =~? '^$HOME>'
        " Only strip the $HOME prefix, avoid double substitution
        let l:subpath = substitute(l:word, '^$HOME', '', '')
        let l:absolute = l:home . l:subpath
        let l:result = substitute(l:absolute, '/+$', '', '')  " clean trailing slashes
    " Convert /home/yourname to $HOME (only if it starts with full HOME)
    elseif l:word =~? '^' . escape(l:home, '/')
        let l:subpath = substitute(l:word, '^' . escape(l:home, '/'), '', '')
        let l:result = '$HOME' . l:subpath
    else
        let l:result = l:word
    endif
    execute "normal! ci" . a:char . l:result
endfunction
nnoremap <silent> <leader>mfe" :call ToggleEnvPath('"')<CR>
nnoremap <silent> <leader>mfe' :call ToggleEnvPath("'")<CR>
nnoremap <silent> <leader>mfe( :call ToggleEnvPath('(')<CR>
nnoremap <silent> <leader>mfe) :call ToggleEnvPath('(')<CR>
nnoremap <silent> <leader>mfe` :call ToggleEnvPath('`')<CR>
nnoremap <silent> <leader>mfew :call ToggleEnvPath('W')<CR>
" Convert current word filepath from ABSOLUTE to RELATIVE
function! ConvertRelativeToAbsolute(char)
    let l:path = expand('<cfile>:p') " :p expand ~ as $HOME
    let l:absolute = trim(system(printf(
                 'realpath %s',
                 shellescape(l:path))))
    exe "normal! ci" . a:char . l:absolute
endfunction
nnoremap <silent> <leader>mfa" :call ConvertRelativeToAbsolute('"')<CR>
nnoremap <silent> <leader>mfa' :call ConvertRelativeToAbsolute("'")<CR>
nnoremap <silent> <leader>mfa( :call ConvertRelativeToAbsolute('(')<CR>
nnoremap <silent> <leader>mfa) :call ConvertRelativeToAbsolute('(')<CR>
nnoremap <silent> <leader>mfa` :call ConvertRelativeToAbsolute('`')<CR>
nnoremap <silent> <leader>mfaw :call ConvertRelativeToAbsolute('W')<CR>
" Convert current word filepath from RELATIVE to ABSOLUTE
function! ConvertAbsoluteToRelative(char)
    let l:path = expand('<cfile>')
    let l:relpath = trim(system(printf(
                 'realpath -s --relative-to=%s %s',
                 shellescape(expand('%:p:h')),
                 shellescape(l:path))))
    exe "normal! ci" . a:char . l:relpath
endfunction
nnoremap <silent> <leader>mfr" :call ConvertAbsoluteToRelative('"')<CR>
nnoremap <silent> <leader>mfr' :call ConvertAbsoluteToRelative("'")<CR>
nnoremap <silent> <leader>mfr( :call ConvertAbsoluteToRelative('(')<CR>
nnoremap <silent> <leader>mfr) :call ConvertAbsoluteToRelative('(')<CR>
nnoremap <silent> <leader>mfr` :call ConvertAbsoluteToRelative('`')<CR>
nnoremap <silent> <leader>mfrw :call ConvertAbsoluteToRelative('W')<CR>
" Rename file path for both text and file location
function! RenameFilePath()
    " Get file path under cursor or visual selection
    let l:orig_path = expand('<cfile>')
    if !filereadable(l:orig_path) && !isdirectory(l:orig_path)
        echoerr "Not a valid file or directory: " . l:orig_path
        return
    endif
    " Prompt for new path
    let l:new_path = input('New path: ', l:orig_path, 'file')
    echo ' '
    if empty(l:new_path) || l:orig_path == l:new_path
        echo "Rename canceled or same name given."
        return
    endif
    " Create destination directory if it doesn't exist
    let l:new_dir = fnamemodify(l:new_path, ':h')
    if !isdirectory(l:new_dir)
        call mkdir(l:new_dir, 'p')
    endif
    " Try renaming the file
    if rename(l:orig_path, l:new_path) == 0
        " Replace text in buffer (only exact matches)
        execute '%s#\V' . escape(l:orig_path, '/.*$^~[]') . '#' . l:new_path . '#g'
        echo "Renamed successfully."
    else
        echoerr "Failed to rename file."
    endif
endfunction
nnoremap <leader>mfR :call RenameFilePath()<CR>
vnoremap <leader>mfR :<C-u>call RenameFilePath()<CR>
" Rename file path and update links contains renamed file path
function! RenameFileAndUpdateLink()
    " Get file path under cursor
    let l:old_path = expand('<cfile>')
    " Prompt user with old_path to edit as new_path
    let l:new_path = input('New path: ', l:old_path)
    echo ' '
    " Cancel if empty or unchanged
    if empty(l:new_path) || l:new_path ==# l:old_path
        echo "Rename cancelled."
        return
    endif
    " Run the python script with both arguments
    let l:cmd = 'python ' . shellescape(s:MARKDOWN_UPDATE_LINK_SCRIPT) .
                 ' ' . shellescape(l:old_path) . ' ' . shellescape(l:new_path)
    echo system(l:cmd)
    " Refresh current buffer (optional)
    checktime
endfunction
command! RenameFileAndUpdateLink call RenameFileViaPython()
nnoremap <leader>mfU :call RenameFileAndUpdateLink()<CR>
vnoremap <leader>mfU :<C-u>call RenameFileAndUpdateLink()<CR>
" Find only HTTP/HTTPS websites
function! FindWebsitesOnly()
    call setqflist([])
    let l:pattern = '\vhttps?://[a-zA-Z0-9._~@%+=:,/?#&$!*-]+'
    call s:CollectMatches(l:pattern, 0)
endfunction
" Find only file paths (non-HTTP/HTTPS URLs)
function! FindFilepathsOnly()
    call setqflist([])
    let l:pattern = '\v(($[A-Z_][A-Z0-9_]*|~|.{1,2})?/)?([a-zA-Z0-9 ._@%+=:,~$!-]+/)+[a-zA-Z0-9 ._@%+=:,~$!-]+.[a-zA-Z0-9]+'
    call s:CollectMatches(l:pattern, 1)
endfunction
" Find both Websites and Filepaths
function! FindAllPathsAndWebsites()
    call setqflist([])
    let l:pattern = '\v(https?://[a-zA-Z0-9._~@%+=:,/?#&$!*-]+)|(($[A-Z_][A-Z0-9_]*|~|.{1,2})?/)?([a-zA-Z0-9 ._@%+=:,~$!-]+/)+[a-zA-Z0-9 ._@%+=:,~$!-]+.[a-zA-Z0-9]+'
    call s:CollectMatches(l:pattern, 0)
endfunction
" Find regex pattern and sent them to quickfix list
function! s:CollectMatches(pattern, skip_http)
    " Enable regex Engine for complex regex pattern matching
    set re=1
    " Regex pattern matching
    let l:matches = []
    for lnum in range(1, line('$'))
        let line_text = getline(lnum)
        let start = 0
        while 1
            let match = matchstrpos(line_text, a:pattern, start)
            if empty(match[0])
                break
            endif
            let match_text = match[0]
            let match_pos = match[1]
            let end_pos = match[2]
            " Optionally skip if part of http(s):// URL
            if a:skip_http && match(match_text, '^https?://') >= 0
                let start = end_pos
                continue
            endif
            " Update match result
            call add(l:matches, {
                   'filename': expand('%:p'),
                   'lnum': lnum,
                   'col': match_pos + 1,
                   'text': match_text
                   })
            let start = end_pos
        endwhile
    endfor
    " Restore regex engine
    set re=0
    " Add to quickfix list
    if empty(l:matches)
        echo "No matches found."
    else
        call setqflist(l:matches, 'r')
        copen
    endif
endfunction
" Captures a screenshot to ./figures and inserts a resized HTML link
" -- Requires system packages: flameshot, xclip
function! CaptureAndPasteImage()
    " Ensure the current markdown file is saved
    if expand('%:p') == ''
        echoerr "Please save the file first to determine the directory path!"
        return
    endif
    " Define directories
    let l:current_dir = expand('%:p:h')
    let l:fig_dir = l:current_dir . '/figures'
    " Create the figures directory if it does not exist
    if !isdirectory(l:fig_dir)
        call mkdir(l:fig_dir, 'p')
    endif
    " Generate filename
    let l:filename = strftime('%Y%m%d_%H%M%S') . '.png'
    let l:filepath = l:fig_dir . '/' . l:filename
    let l:relpath = 'figures/' . l:filename
    " Trigger Flameshot in GUI mode and redirect raw output to the file
    " Vim will pause execution here until you finish selecting your screenshot
    let l:cmd = 'flameshot gui -r > ' . shellescape(l:filepath)
    call system(l:cmd)
    " Verify the file was created and is not empty (in case you hit 'Esc' to cancel)
    if getfsize(l:filepath) > 0
        " Prompt the user for a width ratio
        call inputsave()
        let l:width = input('Enter width (e.g., 50%, 400px, or leave blank for 100%): ')
        call inputrestore()
        " Default to 100% if the user just presses Enter
        if l:width == ''
            let l:width = '100%'
        endif
        " Construct the HTML image tag
        let l:img_tag = '<img src="' . l:relpath . '" width="' . l:width . '" alt="Screenshot">'
        " Insert the tag at the cursor position
        execute "normal! a" . l:img_tag . "<Esc>"
        " Clear the command line and confirm
        redraw
        echo "Screenshot captured and pasted at " . l:width . " width!"
    else
        " Clean up the empty file if you canceled Flameshot
        call system('rm ' . shellescape(l:filepath))
        redraw
        echo "Screenshot canceled."
    endif
endfunction
" Safely move the current markdown file and its 'figures' directory
function! MoveNote()
    " 1. Ensure the current file is saved
    update
    " 2. Gather current paths
    let l:old_file = expand('%:p')
    let l:old_dir = expand('%:p:h')
    let l:old_figures = l:old_dir . '/figures'
    " 3. Prompt for the new destination
    call inputsave()
    let l:new_file = input('Move note to (full or relative path): ', l:old_file, 'file')
    call inputrestore()
    " Abort if empty or unchanged
    if l:new_file == '' || l:new_file == l:old_file
        redraw | echo "Move canceled."
        return
    endif
    " 4. Resolve absolute paths for the destination
    let l:new_file = fnamemodify(l:new_file, ':p')
    let l:new_dir = fnamemodify(l:new_file, ':p:h')
    let l:new_figures = l:new_dir . '/figures'
    " 5. Create new directory if it doesn't exist
    if !isdirectory(l:new_dir)
        call mkdir(l:new_dir, 'p')
    endif
    " 6. Move the Markdown file
    call system('mv ' . shellescape(l:old_file) . ' ' . shellescape(l:new_file))
    " 7. Move the figures directory to follow the note
    if isdirectory(l:old_figures)
        if !isdirectory(l:new_figures)
            " Standard move if no figures folder exists at destination
            call system('mv ' . shellescape(l:old_figures) . ' ' . shellescape(l:new_figures))
        else
            " Safe merge if a figures folder already exists at destination (avoids overwriting)
            call system('cp -n ' . shellescape(l:old_figures) . '/* ' . shellescape(l:new_figures) . '/ && rm -rf ' . shellescape(l:old_figures))
        endif
    endif
    " 8. Swap the Vim buffer to the new file location
    execute 'edit ' . fnameescape(l:new_file)
    execute 'bwipeout ' . fnameescape(l:old_file)
    " Summary
    redraw | echo "Moved note and figures successfully to: " . l:new_dir
endfunction
" Keybindings
noremap <leader>mfA :call FindAllPathsAndWebsites()<CR>
noremap <leader>mfw :call FindWebsitesOnly()<CR>
noremap <leader>mff :call FindFilepathsOnly()<CR>
" Find all headers to quickfix/location list
noremap <leader>mfh <Esc>:lvimgrep /^#/ %<CR>
noremap <leader>mfH <Esc>:vimgrep /^#/ %<CR>
" Insert markdown link to current file
noremap <leader>mfi :FZFMDInsert<CR>
" Insert pandoc style footnote
noremap <leader><bar> :<Esc>i[^]<Left>
" Create a Vim command to trigger the function
nnoremap <leader>mfm :call MoveNote()<CR>
" Captures a screenshot to ./figures and inserts a resized HTML link
nnoremap <leader>mfp :call CaptureAndPasteImage()<CR>
```
