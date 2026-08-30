" ==============================================================================
" Plugin:        vim-markdown-tools
" File:          plugin/markdown_tools.vim
" Description:   A comprehensive Markdown toolkit for Vim/Neovim.
" Maintainer:    JordanWu1997 <jordankhwu@gmail.com>
" Repository:    https://github.com/JordanWu1997/vim-markdown-tools
" Version:       1.2.0
" License:       MIT License
" ==============================================================================

if exists('g:loaded_markdown_tools')
    finish
endif
let g:loaded_markdown_tools = 1

" --- Configuration Defaults ---
let s:plugin_root = expand('<sfile>:p:h:h')

let g:md_tools_template_dir    = get(g:, 'md_tools_template_dir', s:plugin_root . '/templates/')
let g:md_tools_table_template  = get(g:, 'md_tools_table_template', g:md_tools_template_dir . 'table.html')
let g:md_tools_browser         = get(g:, 'md_tools_browser', $BROWSER)
let g:md_tools_use_template    = get(g:, 'md_tools_use_template', 1)
let g:md_tools_no_mappings     = get(g:, 'md_tools_no_mappings', 0)
let g:md_tools_enable_spell    = get(g:, 'md_tools_enable_spell', 1)
let g:md_tools_author          = get(g:, 'md_tools_author', '')
let g:md_tools_email           = get(g:, 'md_tools_email', '')
let g:md_tools_search_dir      = get(g:, 'md_tools_search_dir', '')

" --- Backward Compatibility Global Aliases ---
function! MarkdownTools_ToggleEnvPath(char) abort
    call markdown_tools#toggle_env_path(a:char)
endfunction

function! MarkdownTools_ConvertRelativeToAbsolute(char) abort
    call markdown_tools#convert_rel_to_abs(a:char)
endfunction

function! MarkdownTools_ConvertAbsoluteToRelative(char) abort
    call markdown_tools#convert_abs_to_rel(a:char)
endfunction

function! MarkdownTools_RenameFilePath() abort
    call markdown_tools#rename_file_path()
endfunction

function! MarkdownTools_FindWebsitesOnly() abort
    call markdown_tools#find_websites_only()
endfunction

function! MarkdownTools_FindFilepathsOnly() abort
    call markdown_tools#find_filepaths_only()
endfunction

function! MarkdownTools_FindAllPathsAndWebsites() abort
    call markdown_tools#find_all_paths_and_websites()
endfunction

function! MarkdownTools_CaptureAndPasteImage() abort
    call markdown_tools#capture_and_paste_image()
endfunction

function! MarkdownTools_MoveNote() abort
    call markdown_tools#move_note()
endfunction

function! MarkdownTools_FindBacklinks() abort
    call markdown_tools#find_backlinks()
endfunction

function! MarkdownTools_FindDeadLinks() abort
    call markdown_tools#find_dead_links()
endfunction

function! MarkdownTools_FindOrphanFigures() abort
    call markdown_tools#find_orphan_figures()
endfunction

function! MarkdownTools_CleanOrphanFigures() abort
    call markdown_tools#clean_orphan_figures()
endfunction

function! MarkdownTools_ToggleCheckbox() abort
    call markdown_tools#toggle_checkbox()
endfunction

function! MarkdownTools_FormatTable() abort
    call markdown_tools#format_table()
endfunction

function! MarkdownTools_GenerateTOC() abort
    call markdown_tools#generate_toc()
endfunction

function! MarkdownTools_FindTodos() abort
    call markdown_tools#find_todos()
endfunction

" --- <Plug> Mappings ---

" Preview & Export
nnoremap <silent> <Plug>(MarkdownToolsOpenBrowser)     :call markdown_tools#open_in_browser()<CR>
nnoremap <silent> <Plug>(MarkdownToolsExportMarp)      :call markdown_tools#export_marp()<CR>
nnoremap <silent> <Plug>(MarkdownToolsOpenMarp)        :call markdown_tools#open_marp_html()<CR>
nnoremap <silent> <Plug>(MarkdownToolsExportPandoc)    :call markdown_tools#export_pandoc()<CR>
nnoremap <silent> <Plug>(MarkdownToolsOpenPandoc)      :call markdown_tools#open_pandoc_html()<CR>

" Editing Utilities
nnoremap <silent> <Plug>(MarkdownToolsToggleCheckbox)  :call markdown_tools#toggle_checkbox()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFormatTable)     :call markdown_tools#format_table()<CR>
nnoremap <silent> <Plug>(MarkdownToolsGenerateTOC)     :call markdown_tools#generate_toc()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindTodos)       :call markdown_tools#find_todos()<CR>

" Insertions
nnoremap <silent> <Plug>(MarkdownToolsInsertImgLink)   i![this_is_an_image]()<Left>
nnoremap <silent> <Plug>(MarkdownToolsInsertImgTag)    i<img src="" title="" width="100%" height="100%"/><Esc>38<Left>i
nnoremap <silent> <Plug>(MarkdownToolsInsertVideoTag)  i<video src="" title="" width="100%" height="100%" controls/><Esc>47<Left>i
nnoremap <silent> <Plug>(MarkdownToolsInsertLink)      i[this_is_a_link]()<Left>
nnoremap <silent> <Plug>(MarkdownToolsInsertCheckbox)  i- [ ]<Space>
nnoremap <silent> <Plug>(MarkdownToolsInsertCodeBlock) i```<CR>```<Up>
nnoremap <silent> <Plug>(MarkdownToolsInsertTag)       i::<Esc>i
nnoremap <silent> <Plug>(MarkdownToolsInsertColorSpan) i<span style="color:"><Esc>F<<Esc>19<Right>i
nnoremap <silent> <Plug>(MarkdownToolsInsertColorSpanClose) a</span><Esc>
nnoremap <silent> <Plug>(MarkdownToolsInsertTable)     :call markdown_tools#insert_table_template()<CR>
nnoremap <silent> <Plug>(MarkdownToolsInsertFootnote)  i[^]<Left>

" Path Tools
nnoremap <silent> <Plug>(MarkdownToolsToggleEnvQuote)    :call markdown_tools#toggle_env_path('"')<CR>
nnoremap <silent> <Plug>(MarkdownToolsToggleEnvSingle)   :call markdown_tools#toggle_env_path("'")<CR>
nnoremap <silent> <Plug>(MarkdownToolsToggleEnvParen)    :call markdown_tools#toggle_env_path('(')<CR>
nnoremap <silent> <Plug>(MarkdownToolsToggleEnvBacktick) :call markdown_tools#toggle_env_path('`')<CR>
nnoremap <silent> <Plug>(MarkdownToolsToggleEnvWord)     :call markdown_tools#toggle_env_path('W')<CR>

nnoremap <silent> <Plug>(MarkdownToolsAbsToRelQuote)     :call markdown_tools#convert_abs_to_rel('"')<CR>
nnoremap <silent> <Plug>(MarkdownToolsAbsToRelSingle)    :call markdown_tools#convert_abs_to_rel("'")<CR>
nnoremap <silent> <Plug>(MarkdownToolsAbsToRelParen)     :call markdown_tools#convert_abs_to_rel('(')<CR>
nnoremap <silent> <Plug>(MarkdownToolsAbsToRelBacktick)  :call markdown_tools#convert_abs_to_rel('`')<CR>
nnoremap <silent> <Plug>(MarkdownToolsAbsToRelWord)      :call markdown_tools#convert_abs_to_rel('W')<CR>

nnoremap <silent> <Plug>(MarkdownToolsRelToAbsQuote)     :call markdown_tools#convert_rel_to_abs('"')<CR>
nnoremap <silent> <Plug>(MarkdownToolsRelToAbsSingle)    :call markdown_tools#convert_rel_to_abs("'")<CR>
nnoremap <silent> <Plug>(MarkdownToolsRelToAbsParen)     :call markdown_tools#convert_rel_to_abs('(')<CR>
nnoremap <silent> <Plug>(MarkdownToolsRelToAbsBacktick)  :call markdown_tools#convert_rel_to_abs('`')<CR>
nnoremap <silent> <Plug>(MarkdownToolsRelToAbsWord)      :call markdown_tools#convert_rel_to_abs('W')<CR>

" File & Asset Management
nnoremap <silent> <Plug>(MarkdownToolsRenameFilePath)   :call markdown_tools#rename_file_path()<CR>
vnoremap <silent> <Plug>(MarkdownToolsRenameFilePath)   :<C-u>call markdown_tools#rename_file_path()<CR>
nnoremap <silent> <Plug>(MarkdownToolsMoveNote)         :call markdown_tools#move_note()<CR>
nnoremap <silent> <Plug>(MarkdownToolsCapturePaste)     :call markdown_tools#capture_and_paste_image()<CR>
nnoremap <silent> <Plug>(MarkdownToolsPasteClipboard)   :call markdown_tools#paste_from_clipboard()<CR>

" Search & Discovery
nnoremap <silent> <Plug>(MarkdownToolsFindAllPaths)     :call markdown_tools#find_all_paths_and_websites()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindWebsites)     :call markdown_tools#find_websites_only()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindFilepaths)    :call markdown_tools#find_filepaths_only()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindHeadersLoc)   :lvimgrep /^#/ %<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindHeadersQf)    :vimgrep /^#/ %<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindBacklinks)    :call markdown_tools#find_backlinks()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindDeadLinks)    :call markdown_tools#find_dead_links()<CR>
nnoremap <silent> <Plug>(MarkdownToolsFindOrphanFigures):call markdown_tools#find_orphan_figures()<CR>
nnoremap <silent> <Plug>(MarkdownToolsCleanOrphanFigures):call markdown_tools#clean_orphan_figures()<CR>

" --- User Commands ---
command! -buffer MarkdownFormatTable        call markdown_tools#format_table()
command! -buffer MarkdownGenerateTOC        call markdown_tools#generate_toc()
command! -buffer MarkdownUpdateTOC          call markdown_tools#generate_toc()
command! -buffer MarkdownToggleCheckbox     call markdown_tools#toggle_checkbox()
command! -buffer MarkdownFindTodos          call markdown_tools#find_todos()
command! -buffer MarkdownFindBacklinks      call markdown_tools#find_backlinks()
command! -buffer MarkdownFindDeadLinks      call markdown_tools#find_dead_links()
command! -buffer MarkdownFindOrphanFigures  call markdown_tools#find_orphan_figures()
command! -buffer MarkdownCleanOrphanFigures call markdown_tools#clean_orphan_figures()
command! -buffer MarkdownMoveNote           call markdown_tools#move_note()
command! -buffer MarkdownCaptureImage       call markdown_tools#capture_and_paste_image()
command! -buffer MarkdownPasteClipboard     call markdown_tools#paste_from_clipboard()
command! -buffer MarkdownRenameFile         call markdown_tools#rename_file_path()
command! -buffer MarkdownExportMarp         call markdown_tools#export_marp()
command! -buffer MarkdownExportPandoc       call markdown_tools#export_pandoc()

" --- Default Mappings Application ---

function! s:ApplyDefaultMappings() abort
    if get(g:, 'md_tools_no_mappings', 0)
        return
    endif

    " Preview & Export
    nmap <buffer> <leader>mo <Plug>(MarkdownToolsOpenBrowser)
    nmap <buffer> <leader>mp <Plug>(MarkdownToolsExportMarp)
    nmap <buffer> <leader>mP <Plug>(MarkdownToolsOpenMarp)
    nmap <buffer> <leader>me <Plug>(MarkdownToolsExportPandoc)
    nmap <buffer> <leader>mE <Plug>(MarkdownToolsOpenPandoc)

    " Editing Utilities
    nmap <buffer> <leader>mx  <Plug>(MarkdownToolsToggleCheckbox)
    nmap <buffer> <leader>mtf <Plug>(MarkdownToolsFormatTable)
    nmap <buffer> <leader>mtc <Plug>(MarkdownToolsGenerateTOC)
    nmap <buffer> <leader>mft <Plug>(MarkdownToolsFindTodos)

    " Insertions
    nmap <buffer> <leader>mi <Plug>(MarkdownToolsInsertImgLink)
    nmap <buffer> <leader>mI <Plug>(MarkdownToolsInsertImgTag)
    nmap <buffer> <leader>mV <Plug>(MarkdownToolsInsertVideoTag)
    nmap <buffer> <leader>ml <Plug>(MarkdownToolsInsertLink)
    nmap <buffer> <leader>mb <Plug>(MarkdownToolsInsertCheckbox)
    nmap <buffer> <leader>mB <Plug>(MarkdownToolsInsertCodeBlock)
    nmap <buffer> <leader>mw <Plug>(MarkdownToolsInsertTag)
    nmap <buffer> <leader>mc <Plug>(MarkdownToolsInsertColorSpan)
    nmap <buffer> <leader>mC <Plug>(MarkdownToolsInsertColorSpanClose)
    nmap <buffer> <leader>mT <Plug>(MarkdownToolsInsertTable)
    nmap <buffer> <leader><bar> <Plug>(MarkdownToolsInsertFootnote)

    " Path Tools
    nmap <buffer> <silent> <leader>mfe" <Plug>(MarkdownToolsToggleEnvQuote)
    nmap <buffer> <silent> <leader>mfe' <Plug>(MarkdownToolsToggleEnvSingle)
    nmap <buffer> <silent> <leader>mfe( <Plug>(MarkdownToolsToggleEnvParen)
    nmap <buffer> <silent> <leader>mfe) <Plug>(MarkdownToolsToggleEnvParen)
    nmap <buffer> <silent> <leader>mfe` <Plug>(MarkdownToolsToggleEnvBacktick)
    nmap <buffer> <silent> <leader>mfew <Plug>(MarkdownToolsToggleEnvWord)

    nmap <buffer> <silent> <leader>mfa" <Plug>(MarkdownToolsRelToAbsQuote)
    nmap <buffer> <silent> <leader>mfa' <Plug>(MarkdownToolsRelToAbsSingle)
    nmap <buffer> <silent> <leader>mfa( <Plug>(MarkdownToolsRelToAbsParen)
    nmap <buffer> <silent> <leader>mfa) <Plug>(MarkdownToolsRelToAbsParen)
    nmap <buffer> <silent> <leader>mfa` <Plug>(MarkdownToolsRelToAbsBacktick)
    nmap <buffer> <silent> <leader>mfaw <Plug>(MarkdownToolsRelToAbsWord)

    nmap <buffer> <silent> <leader>mfr" <Plug>(MarkdownToolsAbsToRelQuote)
    nmap <buffer> <silent> <leader>mfr' <Plug>(MarkdownToolsAbsToRelSingle)
    nmap <buffer> <silent> <leader>mfr( <Plug>(MarkdownToolsAbsToRelParen)
    nmap <buffer> <silent> <leader>mfr) <Plug>(MarkdownToolsAbsToRelParen)
    nmap <buffer> <silent> <leader>mfr` <Plug>(MarkdownToolsAbsToRelBacktick)
    nmap <buffer> <silent> <leader>mfrw <Plug>(MarkdownToolsAbsToRelWord)

    nmap <buffer> <leader>mfR <Plug>(MarkdownToolsRenameFilePath)
    vmap <buffer> <leader>mfR <Plug>(MarkdownToolsRenameFilePath)

    " Search & Navigation
    nmap <buffer> <leader>mfA <Plug>(MarkdownToolsFindAllPaths)
    nmap <buffer> <leader>mfw <Plug>(MarkdownToolsFindWebsites)
    nmap <buffer> <leader>mff <Plug>(MarkdownToolsFindFilepaths)
    nmap <buffer> <leader>mfh <Plug>(MarkdownToolsFindHeadersLoc)
    nmap <buffer> <leader>mfH <Plug>(MarkdownToolsFindHeadersQf)
    nmap <buffer> <leader>mfb <Plug>(MarkdownToolsFindBacklinks)
    nmap <buffer> <leader>mfd <Plug>(MarkdownToolsFindDeadLinks)
    nmap <buffer> <leader>mfo <Plug>(MarkdownToolsFindOrphanFigures)
    nmap <buffer> <leader>mfc <Plug>(MarkdownToolsCleanOrphanFigures)

    " Note/Image management
    nmap <buffer> <leader>mfm <Plug>(MarkdownToolsMoveNote)
    nmap <buffer> <leader>mfp <Plug>(MarkdownToolsCapturePaste)
    nmap <buffer> <leader>mfy <Plug>(MarkdownToolsPasteClipboard)
endfunction

" --- Autocommands ---

augroup MarkdownToolsPlugin
    autocmd!

    " Template insertion
    if g:md_tools_use_template
        autocmd BufNewFile *.md,*.markdown call markdown_tools#insert_template()
    endif

    " Buffer setup
    autocmd FileType markdown,wiki call s:OnMarkdownBuffer()
augroup END

function! s:OnMarkdownBuffer() abort
    if g:md_tools_enable_spell
        setlocal spell
    endif
    call s:ApplyDefaultMappings()
endfunction
