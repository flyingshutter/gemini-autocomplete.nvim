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

  -- require('gemini.chat').setup()
  -- require('gemini.instruction').setup()
  -- require('gemini.hint').setup()
  require('gemini.completion').setup()
  -- require('gemini.task').setup()

  vim.api.nvim_create_user_command('Gemini', function(cmd_args)
    if cmd_args.args == 'model' then
      M.create_floating_window()
    end
  end, {
    nargs = '+',
    complete = function()
      -- arglead: the text of the current argument being completed
      -- cmdline: the full command line
      -- cursorpos: the cursor position in the command line
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

function M.create_floating_window()
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
return M
