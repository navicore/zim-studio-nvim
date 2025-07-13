-- Example configuration for zim-studio.nvim

-- Basic setup with defaults
require('zim-studio').setup()

-- Or with custom configuration
require('zim-studio').setup({
  -- Disable automatic audio file opening
  -- auto_play = false,
  
  -- Customize float window
  float_opts = {
    width = 0.9,
    height = 0.9,
    border = 'double',
  },
  
  -- Only integrate with oil.nvim
  integrate_oil = true,
  integrate_nvim_tree = false,
})

-- Example keymaps
vim.keymap.set('n', '<leader>zp', ':ZimPlay<CR>', { desc = 'Play current audio file' })
vim.keymap.set('n', '<leader>zu', ':ZimUpdate<CR>', { desc = 'Update zim sidecars' })
vim.keymap.set('n', '<leader>zl', ':ZimLint<CR>', { desc = 'Lint zim sidecars' })