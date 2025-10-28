local M = {}

-- Default configuration
M.config = {
  auto_play = true,
  float_opts = {
    width = 0.8,
    height = 0.95,  -- Nearly full height to accommodate save dialog
    border = 'rounded',
  },
  integrate_oil = true,
  integrate_nvim_tree = true,
  integrate_ableton = true,
}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Set up commands
  M._setup_commands()
  
  -- Set up autocommands
  if M.config.auto_play then
    M._setup_autocommands()
  end
  
  -- Set up integrations
  if M.config.integrate_oil then
    M._setup_oil_integration()
  end
  
  if M.config.integrate_nvim_tree then
    M._setup_nvim_tree_integration()
  end
end

-- Internal: Set up commands
function M._setup_commands()
  vim.api.nvim_create_user_command('ZimPlay', function(opts)
    M.play(opts.args)
  end, { nargs = '?', complete = 'file' })

  vim.api.nvim_create_user_command('ZimUpdate', function()
    M.update()
  end, {})

  vim.api.nvim_create_user_command('ZimNew', function(opts)
    M.new_project(opts.args)
  end, { nargs = 1 })

  vim.api.nvim_create_user_command('ZimLint', function()
    M.lint()
  end, {})

  vim.api.nvim_create_user_command('ZimAbleton', function(opts)
    M.open_ableton(opts.args)
  end, { nargs = '?', complete = 'file' })
end

-- Internal: Set up autocommands
function M._setup_autocommands()
  local group = vim.api.nvim_create_augroup('ZimStudio', { clear = true })
  
  vim.api.nvim_create_autocmd('BufReadCmd', {
    group = group,
    pattern = { '*.wav', '*.flac' },
    callback = function(ev)
      M.play(ev.file)
      vim.api.nvim_buf_delete(ev.buf, { force = true })
    end,
  })
end

-- Play audio file(s)
function M.play(files)
  -- Handle single file or multiple files
  if not files or files == '' then
    files = vim.fn.expand('%:p')
  end

  -- Convert single file to table
  if type(files) == 'string' then
    files = { files }
  end

  if #files == 0 then
    vim.notify('No file specified', vim.log.levels.ERROR)
    return
  end

  -- Filter and validate audio files
  local audio_files = {}
  for _, file in ipairs(files) do
    if file:match('%.wav$') or file:match('%.flac$') then
      table.insert(audio_files, file)
    end
  end

  if #audio_files == 0 then
    vim.notify('No audio files selected', vim.log.levels.ERROR)
    return
  end

  -- Build command with space-delimited file list
  local file_args = {}
  for _, file in ipairs(audio_files) do
    table.insert(file_args, vim.fn.shellescape(file))
  end
  local cmd = 'zim play ' .. table.concat(file_args, ' ')
  
  -- Use floaterm if available
  if vim.fn.exists(':FloatermNew') == 2 then
    local float_cmd = string.format(
      'FloatermNew --width=%f --height=%f --title=ZIM --autoclose=2 %s',
      M.config.float_opts.width,
      M.config.float_opts.height,
      cmd
    )
    vim.cmd(float_cmd)
  elseif pcall(require, 'toggleterm') then
    -- Use toggleterm if available
    local Terminal = require('toggleterm.terminal').Terminal
    local zim_term = Terminal:new({
      cmd = cmd,
      direction = 'float',
      float_opts = M.config.float_opts,
      close_on_exit = true,
      on_open = function(term)
        vim.cmd('startinsert!')
      end,
    })
    zim_term:toggle()
  else
    -- Fallback to built-in terminal
    M._open_float_term(cmd)
  end
end

-- Update sidecar files
function M.update()
  local cmd = 'zim update .'
  
  if vim.fn.exists(':FloatermNew') == 2 then
    vim.cmd('FloatermNew --autoclose=2 ' .. cmd)
  else
    vim.cmd('!' .. cmd)
  end
end

-- Create new project
function M.new_project(name)
  if not name or name == '' then
    vim.notify('Project name required', vim.log.levels.ERROR)
    return
  end
  
  local cmd = 'zim new ' .. vim.fn.shellescape(name)
  
  if vim.fn.exists(':FloatermNew') == 2 then
    vim.cmd('FloatermNew --autoclose=2 ' .. cmd)
  else
    vim.cmd('!' .. cmd)
  end
end

-- Run lint
function M.lint()
  local cmd = 'zim lint'
  
  if vim.fn.exists(':FloatermNew') == 2 then
    vim.cmd('FloatermNew --autoclose=2 ' .. cmd)
  else
    vim.cmd('!' .. cmd)
  end
end

-- Open Ableton Live project
function M.open_ableton(file)
  file = file or vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file specified', vim.log.levels.ERROR)
    return
  end

  -- Check if file is an Ableton Live project
  if not file:match('%.als$') then
    vim.notify('Not an Ableton Live project: ' .. file, vim.log.levels.ERROR)
    return
  end

  -- Use macOS open command to launch or switch to Ableton
  local cmd = 'open ' .. vim.fn.shellescape(file)

  -- Run in background without terminal window
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.notify('Failed to open Ableton Live project', vim.log.levels.ERROR)
      else
        vim.notify('Opening in Ableton Live: ' .. vim.fn.fnamemodify(file, ':t'), vim.log.levels.INFO)
      end
    end,
  })
end

-- Internal: Open floating terminal (fallback)
function M._open_float_term(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  
  local width = math.floor(vim.o.columns * M.config.float_opts.width)
  local height = math.floor(vim.o.lines * M.config.float_opts.height)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = M.config.float_opts.border,
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Set up terminal with auto-close on exit
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      -- Close the window when process exits
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end)
    end,
  })
  
  vim.cmd('startinsert')
  
  -- Set up keymaps for the terminal buffer
  vim.api.nvim_buf_set_keymap(buf, 't', '<Esc>', '<C-\\><C-n>', { noremap = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
end

-- oil.nvim integration
function M._setup_oil_integration()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'oil',
    callback = function()
      -- Only set up if oil is actually loaded
      local ok, oil = pcall(require, 'oil')
      if not ok then return end

      -- Override enter key for audio files and Ableton Live projects (normal mode)
      vim.keymap.set('n', '<CR>', function()
        local entry = oil.get_cursor_entry()
        if entry and entry.type == 'file' then
          local ext = entry.name:match('%.([^%.]+)$')
          if ext == 'wav' or ext == 'flac' then
            local dir = oil.get_current_dir()
            local full_path = dir .. entry.name
            M.play(full_path)
          elseif ext == 'als' and M.config.integrate_ableton then
            local dir = oil.get_current_dir()
            local full_path = dir .. entry.name
            M.open_ableton(full_path)
          else
            oil.select()
          end
        else
          oil.select()
        end
      end, { buffer = true, desc = 'Open file, play audio, or launch Ableton' })

      -- Handle visual mode multi-select
      vim.keymap.set('v', '<CR>', function()
        local dir = oil.get_current_dir()

        -- Get visual selection range
        local start_line = vim.fn.line('v')
        local end_line = vim.fn.line('.')

        -- Ensure start is before end
        if start_line > end_line then
          start_line, end_line = end_line, start_line
        end

        -- Collect all audio files and Ableton projects in selection
        local audio_files = {}
        local ableton_files = {}

        for line = start_line, end_line do
          -- Position cursor on line to get entry
          vim.api.nvim_win_set_cursor(0, {line, 0})
          local entry = oil.get_cursor_entry()

          if entry and entry.type == 'file' then
            local ext = entry.name:match('%.([^%.]+)$')
            local full_path = dir .. entry.name

            if ext == 'wav' or ext == 'flac' then
              table.insert(audio_files, full_path)
            elseif ext == 'als' and M.config.integrate_ableton then
              table.insert(ableton_files, full_path)
            end
          end
        end

        -- Exit visual mode
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)

        -- Play audio files if any were selected
        if #audio_files > 0 then
          M.play(audio_files)
          if #ableton_files > 0 then
            vim.notify('Note: Ableton files ignored in multi-select (audio files only)', vim.log.levels.WARN)
          end
        elseif #ableton_files > 0 then
          vim.notify('Cannot open multiple Ableton projects at once', vim.log.levels.WARN)
        else
          vim.notify('No audio files in selection', vim.log.levels.WARN)
        end
      end, { buffer = true, desc = 'Play multiple audio files' })
    end,
  })
end

-- nvim-tree integration
function M._setup_nvim_tree_integration()
  -- Defer setup until nvim-tree is loaded
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'NvimTree',
    callback = function()
      local ok, api = pcall(require, 'nvim-tree.api')
      if not ok then return end

      -- Override enter key for audio files and Ableton Live projects
      vim.keymap.set('n', '<CR>', function()
        local node = api.tree.get_node_under_cursor()
        if node and node.type == 'file' then
          local ext = node.name:match('%.([^%.]+)$')
          if ext == 'wav' or ext == 'flac' then
            M.play(node.absolute_path)
          elseif ext == 'als' and M.config.integrate_ableton then
            M.open_ableton(node.absolute_path)
          else
            api.node.open.edit()
          end
        else
          api.node.open.edit()
        end
      end, { buffer = true, desc = 'Open file, play audio, or launch Ableton' })
    end,
  })
end

return M