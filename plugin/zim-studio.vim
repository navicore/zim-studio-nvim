" Prevent loading file twice
if exists('g:loaded_zim_studio')
  finish
endif
let g:loaded_zim_studio = 1

" Save compatible mode
let s:save_cpo = &cpo
set cpo&vim

" Check if Neovim
if !has('nvim')
  echoerr 'zim-studio.nvim requires Neovim'
  finish
endif

" Initialize the plugin with Lua
lua require('zim-studio')

" Restore compatible mode
let &cpo = s:save_cpo
unlet s:save_cpo