# vim-markdown-tools

A comprehensive Markdown toolkit for Vim and Neovim, designed to streamline your documentation, Personal Knowledge Management (PKM), and note-taking workflow.

## Requirements

Before using this plugin, ensure you have the following system dependencies installed:

- **Linux / Unix System**: Tested on Linux (X11 & Wayland).
- **flameshot** / **grim + slurp** / **screencapture**: For screenshot capture.
- **xclip** / **wl-paste** / **pngpaste**: For clipboard management and screenshot/image pasting.
- **ripgrep (`rg`)** *(optional, recommended)*: For instant workspace-wide backlink searches.
- **marp-cli**: For generating presentation slides from Markdown.
- **pandoc**: For exporting Markdown to standalone HTML with custom templates.
- **realpath**: For path resolution.

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'JordanWu1997/vim-markdown-tools'
```

## Features

- **📝 Smart Templates**: Automatically populates new `.md` files with customizable templates (including dynamic `{{TITLE}}`, `{{AUTHOR}}`, `{{EMAIL}}`, and auto-updating timestamps).
- **📊 GFM Table Auto-Formatter**: Automatically formats and aligns Markdown pipe tables with a single keystroke (`<leader>mtf`), respecting column alignments (`:---`, `:---:`, `---:`).
- **📑 In-Buffer Table of Contents (TOC)**: Automatically generate or update a GitHub-compatible Table of Contents (`<!-- TOC -->`) with anchor links (`<leader>mtc`).
- **☑️ Interactive Checkbox Cycling & Todo Search**:
  - Toggle and cycle checkbox states: `- [ ]` $\rightarrow$ `- [o]` *(in progress)* $\rightarrow$ `- [X]` *(done)* $\rightarrow$ `- [-]` *(cancelled)* via `<leader>mx`.
  - Search all unfinished tasks across the note and view them in Quickfix via `<leader>mft`.
- **📸 Screenshot & Clipboard Integration**:
  - Capture a region with `flameshot`, `grim`, or `screencapture`, save it automatically to `./figures`, and insert a resized `<img>` tag.
  - Paste images directly from the system clipboard (`<leader>mfy`) without reopening screenshot GUIs.
- **🔗 Bi-Directional Backlink Discovery**: Instant search for all inbound references, markdown links, or wiki-style links pointing to the current note across your workspace/vault (`<leader>mfb`).
- **🧹 Dead Link & Multi-Note Aware Orphan Asset Cleaner**:
  - **Dead Link Finder**: Scans local links and images in your note to flag missing target files into the Quickfix list (`<leader>mfd`).
  - **Multi-Note Aware Figure Cleaner**: Scans all `.md` files sharing the `./figures` directory to guarantee assets used by sibling notes are never deleted. Offers safe archiving to `./figures/.trash/` (`<leader>mfc`).
- **📂 Smart Note Moving**: Move a Markdown note to a new path while automatically migrating and merging its `./figures` directory (`<leader>mfm`).
- **🔀 Path Management**:
  - Toggle between absolute paths and `$HOME`-prefixed paths.
  - Convert between absolute and relative paths on the fly.
  - Rename files/directories under the cursor and update buffer references automatically.
- **👁️ Async Preview & Export**:
  - Non-blocking async export to standalone HTML via Pandoc or slides via Marp.
  - Instant browser preview.
- **🔌 Standard `<Plug>` Mappings**: Fully remappable actions and optional default keybindings.

---

## Keybindings

All default mappings are buffer-local to `markdown` and `wiki` filetypes and use `<leader>` as the prefix.

| Category                | Mapping             | Action                                                                                               | `<Plug>` Target                             |
| :---------------------- | :------------------ | :--------------------------------------------------------------------------------------------------- | :------------------------------------------ |
| **Editing Utilities**   | `<leader>mtf`       | Format / Align Markdown table under cursor                                                           | `<Plug>(MarkdownToolsFormatTable)`          |
|                         | `<leader>mtc`       | Generate or update Table of Contents (TOC)                                                           | `<Plug>(MarkdownToolsGenerateTOC)`          |
|                         | `<leader>mx`        | Toggle / Cycle checkbox state (`[ ]` $\\rightarrow$ `[o]` $\\rightarrow$ `[x]` $\\rightarrow$ `[-]`) | `<Plug>(MarkdownToolsToggleCheckbox)`       |
|                         | `<leader>mft`       | Find pending TODOs in note (Quickfix)                                                                | `<Plug>(MarkdownToolsFindTodos)`            |
| **Search & Discovery**  | `<leader>mfb`       | Find Backlinks to current note (Quickfix)                                                            | `<Plug>(MarkdownToolsFindBacklinks)`        |
|                         | `<leader>mfd`       | Find Dead / Broken links in note (Quickfix)                                                          | `<Plug>(MarkdownToolsFindDeadLinks)`        |
|                         | `<leader>mfo`       | Find Orphan figures across all notes (Quickfix)                                                      | `<Plug>(MarkdownToolsFindOrphanFigures)`    |
|                         | `<leader>mfc`       | Clean / Archive orphan figures (Safe prompt)                                                         | `<Plug>(MarkdownToolsCleanOrphanFigures)`   |
|                         | `<leader>mfA`       | Find all paths and URLs (Quickfix)                                                                   | `<Plug>(MarkdownToolsFindAllPaths)`         |
|                         | `<leader>mfw`       | Find URLs only (Quickfix)                                                                            | `<Plug>(MarkdownToolsFindWebsites)`         |
|                         | `<leader>mff`       | Find file paths only (Quickfix)                                                                      | `<Plug>(MarkdownToolsFindFilepaths)`        |
|                         | `<leader>mfh`       | Find headers (Location list)                                                                         | `<Plug>(MarkdownToolsFindHeadersLoc)`       |
|                         | `<leader>mfH`       | Find headers (Quickfix list)                                                                         | `<Plug>(MarkdownToolsFindHeadersQf)`        |
| **Assets & Management** | `<leader>mfp`       | Capture & paste screenshot                                                                           | `<Plug>(MarkdownToolsCapturePaste)`         |
|                         | `<leader>mfy`       | Paste image directly from clipboard                                                                  | `<Plug>(MarkdownToolsPasteClipboard)`       |
|                         | `<leader>mfm`       | Move current note & its `./figures` folder                                                           | `<Plug>(MarkdownToolsMoveNote)`             |
|                         | `<leader>mfR`       | Rename file path under cursor & update buffer                                                        | `<Plug>(MarkdownToolsRenameFilePath)`       |
| **Preview & Export**    | `<leader>mo`        | Open current Markdown in browser                                                                     | `<Plug>(MarkdownToolsOpenBrowser)`          |
|                         | `<leader>mp`        | Async export to Marp slides (HTML)                                                                   | `<Plug>(MarkdownToolsExportMarp)`           |
|                         | `<leader>mP`        | Open Marp HTML in browser                                                                            | `<Plug>(MarkdownToolsOpenMarp)`             |
|                         | `<leader>me`        | Async export to Pandoc HTML                                                                          | `<Plug>(MarkdownToolsExportPandoc)`         |
|                         | `<leader>mE`        | Open Pandoc HTML in browser                                                                          | `<Plug>(MarkdownToolsOpenPandoc)`           |
| **Insertions**          | `<leader>mi`        | Insert image link `![text]()`                                                                        | `<Plug>(MarkdownToolsInsertImgLink)`        |
|                         | `<leader>mI`        | Insert HTML `<img>` tag                                                                              | `<Plug>(MarkdownToolsInsertImgTag)`         |
|                         | `<leader>mV`        | Insert HTML `<video>` tag                                                                            | `<Plug>(MarkdownToolsInsertVideoTag)`       |
|                         | `<leader>ml`        | Insert link `[text]()`                                                                               | `<Plug>(MarkdownToolsInsertLink)`           |
|                         | `<leader>mb`        | Insert checkbox `- [ ]`                                                                              | `<Plug>(MarkdownToolsInsertCheckbox)`       |
|                         | `<leader>mB`        | Insert code block ```` ``` ````                                                                      | `<Plug>(MarkdownToolsInsertCodeBlock)`      |
|                         | `<leader>mw`        | Insert tag `::`                                                                                      | `<Plug>(MarkdownToolsInsertTag)`            |
|                         | `<leader>mc`        | Insert opening `<span style="color:">`                                                               | `<Plug>(MarkdownToolsInsertColorSpan)`      |
|                         | `<leader>mC`        | Insert closing `</span>`                                                                             | `<Plug>(MarkdownToolsInsertColorSpanClose)` |
|                         | `<leader>mT`        | Insert HTML table template                                                                           | `<Plug>(MarkdownToolsInsertTable)`          |
|                         | `<leader>\|`        | Insert Pandoc footnote `[^]`                                                                         | `<Plug>(MarkdownToolsInsertFootnote)`       |
| **Path Tools**          | `<leader>mfe{char}` | Toggle `$HOME` path for text in `{char}`                                                             | `<Plug>(MarkdownToolsToggleEnv...)`         |
|                         | `<leader>mfa{char}` | Convert Relative to Absolute for `{char}`                                                            | `<Plug>(MarkdownToolsRelToAbs...)`          |
|                         | `<leader>mfr{char}` | Convert Absolute to Relative for `{char}`                                                            | `<Plug>(MarkdownToolsAbsToRel...)`          |

*\*Note: For path tools, `{char}` can be `"`, `'`, `(`, `)`, `` ` ``, or `w` (word).*

---

## Commands

- `:MarkdownFormatTable` — Auto-align Markdown pipe table under cursor.
- `:MarkdownGenerateTOC` / `:MarkdownUpdateTOC` — Generate or update in-buffer Table of Contents.
- `:MarkdownToggleCheckbox` — Toggle / cycle task checkbox.
- `:MarkdownFindTodos` — Search pending tasks and list them in Quickfix.
- `:MarkdownFindBacklinks` — Populate Quickfix with all notes referencing the current file.
- `:MarkdownFindDeadLinks` — Check local links in the current buffer and list broken references.
- `:MarkdownFindOrphanFigures` — Scan all notes sharing `./figures` and list unreferenced images in Quickfix.
- `:MarkdownCleanOrphanFigures` — Safely move unused figures to `./figures/.trash/` or delete them.
- `:MarkdownMoveNote` — Move current note and automatically migrate its `./figures` folder.
- `:MarkdownCaptureImage` — Take interactive screenshot and insert image tag.
- `:MarkdownPasteClipboard` — Paste image from clipboard to `./figures` and insert tag.
- `:MarkdownRenameFile` — Rename file under cursor and update references.
- `:MarkdownExportMarp` — Asynchronously compile note into Marp slides.
- `:MarkdownExportPandoc` — Asynchronously compile note into Pandoc HTML.

---

## Customizing Keybindings

To disable default mappings and define your own:

```vim
let g:md_tools_no_mappings = 1

" Example custom mappings:
autocmd FileType markdown nnoremap <buffer> <leader>tf <Plug>(MarkdownToolsFormatTable)
autocmd FileType markdown nnoremap <buffer> <leader>tc <Plug>(MarkdownToolsGenerateTOC)
autocmd FileType markdown nnoremap <buffer> <leader>tx <Plug>(MarkdownToolsToggleCheckbox)
autocmd FileType markdown nnoremap <buffer> <leader>nb <Plug>(MarkdownToolsFindBacklinks)
autocmd FileType markdown nnoremap <buffer> <leader>nd <Plug>(MarkdownToolsFindDeadLinks)
autocmd FileType markdown nnoremap <buffer> <leader>np <Plug>(MarkdownToolsCapturePaste)
autocmd FileType markdown nnoremap <buffer> <leader>ny <Plug>(MarkdownToolsPasteClipboard)
```

---

## Configuration

Customize plugin variables in your `.vimrc` or `init.vim`:

```vim
" Disable default keybindings (default: 0)
let g:md_tools_no_mappings = 0

" Custom workspace / vault search directory for backlinks (default: Git root or current directory)
let g:md_tools_search_dir = '~/my_notes_vault'

" Directory where templates are stored
let g:md_tools_template_dir = '~/.vim/plugged/vim-markdown-tools/templates/'

" HTML table template path
let g:md_tools_table_template = g:md_tools_template_dir . 'table.html'

" Browser used for previewing (defaults to $BROWSER or xdg-open)
let g:md_tools_browser = 'google-chrome'

" Whether to insert template for new files (default: 1)
let g:md_tools_use_template = 1

" User details for dynamic templates ({{AUTHOR}}, {{EMAIL}})
let g:md_tools_author = 'Your Name'
let g:md_tools_email  = 'your.email@example.com'

" Enable spell check on markdown buffers (default: 1)
let g:md_tools_enable_spell = 1
```

---

## License

This project is licensed under the MIT License.
