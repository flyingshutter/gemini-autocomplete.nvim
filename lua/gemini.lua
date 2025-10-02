local config = require('gemini.config')
local api = require('gemini.api')
local util = require('gemini.util')

local M = {}

M.setup = function(opts)
  if not vim.fn.executable('curl') then
    vim.notify("Gemini: Could not find executable: 'curl'", vim.log.levels.ERROR)
    return
  end

  if not util.is_nvim_version_ge(0, 10, 0) then
    vim.notify('Gemini: neovim version may be too old', vim.log.levels.WARN)
    return
  end

  vim.api.nvim_create_augroup('Gemini', { clear = true })

  config.set_config(opts)
  -- M.enabled = config.config.completion.enabled
  require('gemini.completion').setup()

  if config.config.general.mini_statusline then 
    M.mini_statusline()
  end

  vim.api.nvim_create_user_command('Gemini', function(cmd_args)
    if cmd_args.args == 'model' then
      M.choose_model()
    end
  end, {
    nargs = '+',
    complete = function(arglead, cmdline, cursorpos)
      return { 'model' }
    end,
    desc = 'My first command with arguments and autocompletion.',
  })
end

local function win_config()
  local width = 80
  local height = 5
  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = 'rounded',
    title = 'Select Gemini Model',
  }
end

M.choose_model = function()
  local available_models = {}
  for _, model_name in pairs(api.MODELS) do
    table.insert(available_models, model_name)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, available_models)
  vim.api.nvim_open_win(buf, true, win_config())

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Close Floating [W]in' })

  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    config.set_config({ model = { model_id = line } })
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Close Floating [W]in' })
end

M.mini_statusline = function()
  require 'mini.statusline'.config.content.active = function()
    local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
    local git = MiniStatusline.section_git { trunc_width = 40 }
    local diff = MiniStatusline.section_diff { trunc_width = 75 }
    local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
    local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
    local filename = MiniStatusline.section_filename { trunc_width = 140 }
    local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
    local location = MiniStatusline.section_location { trunc_width = 75 }
    local search = MiniStatusline.section_searchcount { trunc_width = 75 }

    local gemini_model = require('gemini.config').config.model.model_id
    local pos = string.find(gemini_model, '-')
    local gemini_model_short = string.sub(gemini_model, pos + 1)
    local hl_gemini = 'PmenuMatchSel'
    if not require('gemini').is_enabled() then
      hl_gemini = 'DiffDelete'
    end

    return MiniStatusline.combine_groups {
      { hl = mode_hl, strings = { mode } },
      { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
      '%<', -- Mark general truncate point
      { hl = 'MiniStatuslineFilename', strings = { filename } },
      '%=', -- End left alignment
      { hl = hl_gemini, strings = { gemini_model_short } },
      { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
      { hl = mode_hl, strings = { search, location } },
    }
  end
end

M.toggle_enabled = function()
  config.config.completion.enabled = not config.config.completion.enabled
  if config.config.completion.enabled then
    print 'Gemini: Autocomplete enabled'
  else
    print 'Gemini: Autocomplete disabled'
  end
end

M.is_enabled = function()
  return config.config.completion.enabled
end

return M
