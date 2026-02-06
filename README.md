# vim-rjnvim

A Neovim Lua port of [vim-rjvim](https://github.com/li-ruijie/vim-rjvim), providing helper functions and utilities for enhanced Vim/Neovim experience.

## Features

### Application Functions (App_*)
- **Colorscheme Management**: Safe colorscheme switching with highlight link preservation
- **Font Size Control**: Dynamic font size adjustment in GUI mode
- **Color Scheme Cycling**: Navigate through available colorschemes
- **Conceal Auto Mode**: Automatic conceal level management during insert mode
- **GUI Tab Labels**: Enhanced tab labels with buffer information

### Text Formatting Functions (Fmt_*)
- **Auto Format Toggle**: Toggle automatic text formatting
- **Text Formatting**: Multiple text formatting modes (short, long, isolated)
- **Line Breaking**: Break text at periods
- **File Format Fixing**: Resolve file format issues
- **Blank Line Insertion**: Insert blank lines above/below cursor

### Filetype Functions (Ft_*)
- **Shell Script Initialization**: Enhanced shell script file settings
- **Template System**: File template loading based on file extension

### System Functions (Sys_*)
- **Backup System**: Advanced backup file management
- **System Detection**: OS and environment detection
- **Insert Mode Muting**: Control event firing during insert mode operations

### Utility Functions (Ut_*)
- **Line Numbering**: Add line numbers to text
- **Separator Generation**: Generate comment separators
- **Variable Initialization**: Safe variable initialization
- **Multi-function Application**: Apply multiple functions in sequence
- **Spell Checking**: Quick spell correction
- **DTWS (Delete Trailing WhiteSpace)**: Comprehensive trailing whitespace management

## Installation

### Using lazy.nvim
```lua
{ 'li-ruijie/vim-rjnvim' }
```

### Using packer.nvim
```lua
use 'li-ruijie/vim-rjnvim'
```

### Using vim-plug
```vim
Plug 'li-ruijie/vim-rjnvim'
```

## Usage

### Key Mappings (Plug Mappings)

The plugin provides `<Plug>` mappings that you can map to your preferred keys:

```lua
-- Font size control
vim.keymap.set('n', '<leader>f+', '<Plug>(rjvim-fontsize-increase)')
vim.keymap.set('n', '<leader>f-', '<Plug>(rjvim-fontsize-decrease)')
vim.keymap.set('n', '<leader>f0', '<Plug>(rjvim-fontsize-default)')

-- Colorscheme cycling
vim.keymap.set('n', '<leader>cn', '<Plug>(rjvim-colorscheme-next)')
vim.keymap.set('n', '<leader>cp', '<Plug>(rjvim-colorscheme-prev)')

-- Spell checking
vim.keymap.set('n', '<leader>z', '<Plug>(rjvim-spell-accept-first)')
vim.keymap.set('i', '<C-z>', '<Plug>(rjvim-spell-accept-first)')
```

### Commands

The plugin provides numerous commands:

#### Font and Appearance
- `:RjvimFontSizeIncrease` - Increase font size
- `:RjvimFontSizeDecrease` - Decrease font size
- `:RjvimFontSizeDefault` - Reset to default font size
- `:RjvimColorschemeNext` - Switch to next colorscheme
- `:RjvimColorschemePrev` - Switch to previous colorscheme

#### Text Formatting
- `:RjvimFormatTextShort` - Format text with short width
- `:RjvimFormatTextLong` - Format text with long width
- `:RjvimFormatTextIsolated` - Format text with isolation
- `:RjvimAutoFormatToggle` - Toggle auto formatting
- `:RjvimBreakOnPeriod` - Break text on periods
- `:RjvimFixFileFormat` - Fix file format issues

#### System Utilities
- `:RjvimBackupEnable` - Enable backup system
- `:RjvimSysInfo` - Detect and set system information
- `:RjvimShInit` - Initialize shell script settings
- `:RjvimTemplates` - Load file templates

#### Utilities
- `:RjvimAddLineNumbers [pad] [width]` - Add line numbers
- `:RjvimGenSep [comment] [head] [body] [tail] [level]` - Generate separators
- `:DTWS` - Delete trailing whitespace

### Programmatic Usage

You can also use the functions directly in Lua:

```lua
local rjvim9 = require('rjvim9')

-- Change font size
rjvim9.app_fontsize('+')  -- increase
rjvim9.app_fontsize('-')  -- decrease
rjvim9.app_fontsize('default')  -- reset

-- Switch colorschemes
rjvim9.app_colourssw_switchcolours('+')  -- next
rjvim9.app_colourssw_switchcolours('-')  -- previous

-- Format text
rjvim9.fmt_formattext_short()
rjvim9.fmt_formattext_long()

-- Delete trailing whitespace
rjvim9.ut_dtws_delete(1, vim.fn.line('$'))
```

## DTWS (Delete Trailing WhiteSpace)

The plugin includes a comprehensive trailing whitespace management system:

### Configuration
```lua
-- Enable DTWS (0 = disabled, 1 = enabled, 'always' = always enabled)
vim.g['rjvim9#DTWS'] = 1

-- Action to take ('abort' = abort write, 'delete' = auto-delete)
vim.g['rjvim9#DTWS_action'] = 'delete'
```

### Usage
- `:DTWS` - Manually delete trailing whitespace in range (default: whole file)
- Automatic deletion on file write (if configured)
- Buffer-local configuration support

## Migration from Vim9script

This Lua version maintains API compatibility with the original Vim9script version while providing:

- Better Neovim integration
- Improved performance
- Modern Neovim API usage
- Enhanced error handling
- Lua-native features

### Key Differences
1. Function names use snake_case instead of PascalCase
2. Uses Neovim's Lua API instead of Vimscript commands where possible
3. Enhanced error handling with `pcall` and proper error messages
4. Modern autocmd and keymap APIs

## Configuration Example

```lua
-- In your init.lua or plugin configuration

-- Enable DTWS with auto-delete
vim.g['rjvim9#DTWS'] = 1
vim.g['rjvim9#DTWS_action'] = 'delete'

-- Set up key mappings
local rjvim9_keys = {
  -- Font size
  ['<leader>f+'] = '<Plug>(rjvim-fontsize-increase)',
  ['<leader>f-'] = '<Plug>(rjvim-fontsize-decrease)',
  ['<leader>f0'] = '<Plug>(rjvim-fontsize-default)',

  -- Colorschemes
  ['<leader>cn'] = '<Plug>(rjvim-colorscheme-next)',
  ['<leader>cp'] = '<Plug>(rjvim-colorscheme-prev)',

  -- Spell checking
  ['<leader>z'] = '<Plug>(rjvim-spell-accept-first)',
}

for lhs, rhs in pairs(rjvim9_keys) do
  vim.keymap.set('n', lhs, rhs, { silent = true })
end

-- Enable system info detection
require('rjvim9').sys_info()

-- Enable backup system for important files
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.lua,*.vim,*.py,*.js',
  callback = function()
    require('rjvim9').sys_backupenable()
  end
})
```

## License

GPL-3.0