# zim-studio.nvim

A Neovim plugin for integrating [zim-studio](https://github.com/navicore/zim-studio) into your workflow.

## Features

- Open audio files (`.wav`, `.flac`) in zim player automatically
- Launch or switch to Ableton Live projects (`.als`) directly from Neovim
- Integration with file managers (oil.nvim, nvim-tree)
- Vim commands for common zim operations
- Floating terminal windows for zim player

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'navicore/zim-studio-nvim',
  dependencies = {
    'voldikss/vim-floaterm', -- or 'akinsho/toggleterm.nvim'
  },
  config = function()
    require('zim-studio').setup()
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'navicore/zim-studio-nvim',
  requires = { 'voldikss/vim-floaterm' },
  config = function()
    require('zim-studio').setup()
  end
}
```

## Commands

- `:ZimPlay [file]` - Open file in zim player (defaults to current file)
- `:ZimAbleton [file]` - Open Ableton Live project (defaults to current file)
- `:ZimUpdate` - Run `zim update .` in current directory
- `:ZimNew "Project Name"` - Create new zim project
- `:ZimLint` - Run `zim lint` in current directory

## Configuration

```lua
require('zim-studio').setup({
  -- Automatically open audio files with zim player
  auto_play = true,

  -- Float window configuration
  float_opts = {
    width = 0.8,
    height = 0.95,  -- Nearly full height for save dialog
    border = 'rounded',
  },

  -- Integration with file managers
  integrate_oil = true,
  integrate_nvim_tree = true,
  integrate_ableton = true,  -- Launch Ableton Live projects on macOS
})
```

## File Manager Integration

### oil.nvim

When `integrate_oil` is enabled, pressing `<CR>` on `.wav` or `.flac` files will open them in zim player. When `integrate_ableton` is also enabled, pressing `<CR>` on `.als` files will launch or switch to Ableton Live.

### nvim-tree

When `integrate_nvim_tree` is enabled, pressing `<CR>` on audio files will open them in zim player. With `integrate_ableton` enabled, `.als` files will open in Ableton Live.

## Requirements

- Neovim >= 0.8.0
- [zim-studio](https://github.com/navicore/zim-studio) installed and in PATH
- vim-floaterm or toggleterm.nvim for floating windows

## License

MIT