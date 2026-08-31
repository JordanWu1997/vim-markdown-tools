# vim-markdown-tools

A comprehensive Markdown toolkit for Vim and Neovim, designed to streamline your documentation and note-taking workflow.

## Requirements

Before using this plugin, ensure you have the following system dependencies installed:

- **Linux System**: Currently, this plugin has only been tested on Linux.
- **flameshot**: For capturing screenshots.
- **xclip**: For clipboard management (required by flameshot integration).
- **marp-cli**: For generating presentations from Markdown.
- **pandoc**: For exporting Markdown to various formats (specifically HTML).
- **realpath**: For path resolution (usually pre-installed on most Linux distributions).

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'JordanWu1997/vim-markdown-tools'
```

## Features

- **📝 Smart Templates**: Automatically populates new `.md` files with a customizable template (including auto-updating timestamps).
- **📸 Screenshot Integration**: Capture a region of your screen with `flameshot`, save it automatically to a `./figures` folder, and insert a resized HTML `<img>` tag directly into your document.
- **🔗 Path Management**:
  - Toggle between absolute paths and `$HOME`-prefixed paths.
  - Convert between absolute and relative paths on the fly.
  - Rename files/directories under the cursor and update the reference in the current buffer.
  - Localize resources for associated file migration (like `../figures` to `./figures`)
- **👁️ Preview & Export**:
  - Instant preview in your default browser.
  - Export to HTML using Pandoc with Bootstrap templates.
  - Export to presentations using Marp.
- **🔍 Search & Quickfix**: Quickly find all embedded websites, local file paths, or Markdown headers and populate them into the Quickfix or Location list.
- **⚡ Quick Insertions**: Dedicated mappings for images, videos, checkboxes, code blocks, color spans, and tables.

## Keybindings

All mappings are local to `markdown` filetypes and typically use `<leader>` as the prefix.

| **Preview/Export** |              **Action**               |
| :----------------: | :-----------------------------------: |
|    `<leader>mo`    | Open current Markdown file in browser |
|    `<leader>mp`    |     Export to Marp slides (HTML)      |
|    `<leader>mP`    |       Open Marp HTML in browser       |
|    `<leader>me`    |  Export to Pandoc HTML (standalone)   |
|    `<leader>mE`    |      Open Pandoc HTML in browser      |

| **Insertions** |               **Action**               |
| :------------: | :------------------------------------: |
|  `<leader>mi`  |     Insert image link `![text]()`      |
|  `<leader>mI`  |        Insert HTML `<img>` tag         |
|  `<leader>mV`  |       Insert HTML `<video>` tag        |
|  `<leader>ml`  |         Insert link `[text]()`         |
|  `<leader>mb`  |        Insert checkbox `- [ ]`         |
|  `<leader>mB`  |    Insert code block ```` ``` ````     |
|  `<leader>mw`  |            Insert tag `::`             |
|  `<leader>mc`  | Insert opening `<span style="color:">` |
|  `<leader>mC`  |        Insert closing `</span>`        |
|  `<leader>mT`  |       Insert HTML table template       |
|  `<leader>\|`  |   Insert Pandoc-style footnote `[^]`   |

|   **Path Tools**    |                                 **Action**                                 |
| :-----------------: | :------------------------------------------------------------------------: |
| `<leader>mfe{char}` |   Toggle Env Path (expand/collapse `$HOME`) for path wrapped in `{char}`   |
| `<leader>mfa{char}` |           Convert path to Absolute for path wrapped in `{char}`            |
| `<leader>mfr{char}` |           Convert path to Relative for path wrapped in `{char}`            |
|    `<leader>mfR`    |    Rename file path under cursor and update buffer (work for all files)    |
|    `<leader>mfL`    | Localize resources path (all outlinks contains `figures/` in current file) |
|    `<leader>mfI`    |          Insert markdown file path using fuzzy matching file name          |

| **Search & Navigation** |                  **Action**                   |
| :---------------------: | :-------------------------------------------: |
|      `<leader>mfg`      |           Grep all files in vimwiki           |
|      `<leader>mfb`      | Find all backlinks to current file (Quickfix) |
|      `<leader>mfo`      | Find all outlinks to current file (Quickfix)  |
|      `<leader>mfA`      |    Find all paths and websites (Quickfix)     |
|      `<leader>mfw`      |         Find websites only (Quickfix)         |
|      `<leader>mff`      |        Find file paths only (Quickfix)        |
|      `<leader>mfh`      |         Find headers (Location list)          |
|      `<leader>mfH`      |         Find headers (Quickfix list)          |

| **Management** |                **Action**                |
| :------------: | :--------------------------------------: |
| `<leader>mfp`  | Capture and paste screenshot (Flameshot) |

*Note: For path tools, `{char}` can be `"`, `'`, `(`, `)`, `` ` ``, or `w` (for word).*

## Configuration

You can customize the plugin by setting these variables in your `init.vim` or `.vimrc`:

```vim
" Directory where templates are stored
let g:md_tools_template_dir = '~/.vim/plugged/vim-markdown-tools/templates/'

" Path to the HTML table template
let g:md_tools_table_template = g:md_tools_template_dir . 'table.html'

" Browser used for previewing
let g:md_tools_browser = 'google-chrome'

" Whether to use templates for new files (1 = yes, 0 = no)
let g:md_tools_use_template = 1
```

## Development Note

- This plugin was developed and packed with the assistance of **gemini-3**.
- **OS Compatibility**: The scripts and integrations (like `flameshot`, `realpath`, `mv`) have only been tested on **Linux** systems.

## License

This project is licensed under the MIT License.
