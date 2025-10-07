local config = require('gemini-autocomplete.config')
local api = require('gemini-autocomplete.api')
local util = require('gemini-autocomplete.util')
local context = require('gemini-autocomplete.context')
local completion = require('gemini-autocomplete.completion')

local M = {}

local function gemini_add_file(cmd_args)
  util.notify(vim.inspect(cmd_args.fargs), vim.log.levels.DEBUG)
  if #cmd_args.fargs < 2 then
    vim.notify('Error: Gemini-autocomplete add_file expected at least 1 filename', vim.log.levels.ERROR)
    return
  end
  for idx = 2, #cmd_args.fargs do
    local file_name = vim.fn.expand(cmd_args.fargs[idx])
    if file_name == '' and cmd_args.fargs[idx] == '%' then
      vim.notify('Gemini-autocomplete Error: filepath expands to empty string (common mistake: a new file has to be saved once before adding)', vim.log.levels.ERROR)
      return
    elseif file_name == '' then
      vim.notify('Gemini-autocomplete Error: filepath expands to empty string', vim.log.levels.ERROR)
      return
    end
    util.notify('Gemini-autocomplete: file_name is ' .. file_name, vim.log.levels.DEBUG)
    context.add_file(file_name)
  end
  util.notify(cmd_args.fargs[2], vim.log.levels.DEBUG)
end

local function gemini_remove_file(cmd_args)
  util.notify(vim.inspect(cmd_args.fargs), vim.log.levels.DEBUG)
  if #cmd_args.fargs < 2 then
    vim.notify('Error: Gemini-autocomplete add_file expected at least 1 filename', vim.log.levels.ERROR)
    return
  end
  for idx = 2, #cmd_args.fargs do
    local file_name = vim.fn.expand(cmd_args.fargs[idx])
    if file_name == '' then
      vim.notify('Gemini-autocomplete Error: filepath expands to empty string', vim.log.levels.ERROR)
      return
    end
    file_name = vim.fn.fnamemodify(file_name, ':p')
    util.notify('file_name is ' .. file_name, vim.log.levels.DEBUG)

    context.remove_file(file_name)
  end
  util.notify(cmd_args.fargs[2], vim.log.levels.DEBUG)
end

local function define_colorscheme()
  vim.api.nvim_set_hl(0, 'GeminiEnabled', { fg = '#5f9a53', italic = false, bold = true })
  vim.api.nvim_set_hl(0, 'GeminiDisabled', { fg = '#988c5d', italic = false, bold = false })
end

M.setup = function(opts)
  opts = opts or {}

  if not vim.fn.executable('curl') then
    vim.notify("Gemini-autocomplete: Could not find executable: 'curl'", vim.log.levels.ERROR)
    return
  end
  if not util.is_nvim_version_ge(0, 10, 0) then
    vim.notify('Gemini-autocomplete: neovim version may be too old', vim.log.levels.WARN)
    return
  end

  -- general setup
  config.set_config(opts)
  _G.gemini = {}
  vim.api.nvim_create_augroup('Gemini-autocomplete', { clear = true })
  require('gemini-autocomplete.completion').setup()

  -- make Colorscheme
  vim.api.nvim_create_augroup("Gemini-colorscheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "Gemini-colorscheme",
    callback = define_colorscheme,
  })
  define_colorscheme()

  --- update context on file save
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = 'Gemini-autocomplete',
    callback = function(opts)
      local buf = opts.buf
      for watch_file_name, _ in pairs(context.context) do
        if watch_file_name == vim.api.nvim_buf_get_name(buf) then
          context.context[watch_file_name] = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end
      end
    end,
  })

  -- create Vim Command
  vim.api.nvim_create_user_command('GeminiAutocomplete', function(cmd_args)
    util.notify(vim.inspect(cmd_args), vim.log.levels.DEBUG)
    if cmd_args.args == 'choose_model' then
      M.choose_model()
    elseif cmd_args.fargs[1] == 'add_file' then
      gemini_add_file(cmd_args)
    elseif cmd_args.fargs[1] == 'remove_file' then
      gemini_remove_file(cmd_args)
    elseif cmd_args.args == 'add_git_files' then
      M.add_gitfiles()
    elseif cmd_args.args == 'edit_context' then
      M.edit_context()
    elseif cmd_args.args == 'clear_context' then
      M.clear_context()
    elseif cmd_args.args == 'prompt_code' then
      M.prompt_code()
    else
      vim.notify("Error: Command ':GeminiAutocomplete " .. cmd_args.args .. "' does not exist", vim.log.levels.ERROR)
    end
  end, {
    nargs = '+',
    complete = function(arglead, cmdline, cursorpos)
      return { 'choose_model', 'add_file', 'remove_file', 'add_git_files', 'edit_context', 'clear_context', 'prompt_code' }
    end,
    desc = 'GeminiAutocomplete commands: choose_model, add_file, remove_file, add_git_files, edit_context, clear_context, prompt_code',
  })
end

local function win_config(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend('force', { size = { 60, 20 }, title = 'Unnamed Window' }, opts)
  local width = opts.size[1]
  local height = opts.size[2]
  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = 'rounded',
    title = opts.title .. ' (<Esc>: abort, <Enter>: confirm)',
  }
end

M.edit_context = function()
  local buf = vim.api.nvim_create_buf(false, true)
  local file_names = {}
  for file_name, _ in pairs(context.context) do
    table.insert(file_names, file_name)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, file_names)
  local height = math.min(vim.o.lines - 9, math.max(40, vim.api.nvim_buf_line_count(buf)))
  vim.api.nvim_open_win(buf, true, win_config({ size = { 90, height }, title = 'Edit Context' }))

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Abort' })

  vim.keymap.set('n', '<CR>', function()
    local file_names = {}
    for file_name, _ in pairs(context.context) do
      table.insert(file_names, file_name)
    end
    local buf = vim.api.nvim_get_current_buf()
    local new_file_names = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local added, removed = util.get_list_differences(file_names, new_file_names)

    for _, file_name in ipairs(added) do
      if file_name ~= '' then
        context.add_file(file_name)
      end
    end

    for _, file_name in ipairs(removed) do
      context.context[file_name] = nil
    end

    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Confirm' })
end

M.choose_model = function()
  local available_models = {}
  for _, model_name in pairs(api.MODELS) do
    table.insert(available_models, model_name)
  end
  vim.fn.sort(available_models)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, available_models)
  local height = math.min(vim.o.lines - 3, vim.api.nvim_buf_line_count(buf))
  vim.api.nvim_open_win(buf, true, win_config({ size = { 46, height }, title = 'Choose Model' }))

  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Abort' })

  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    config.set_config({ model = { model_id = line } })
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Confirm' })
end

M.toggle_enabled = function()
  config.get_config().completion.enabled = not config.get_config().completion.enabled
  if config.get_config().completion.enabled then
    print('Gemini-autocomplete: Autocomplete enabled')
  else
    print('Gemini-autocomplete: Autocomplete disabled')
  end
  vim.api.nvim_command('redraw!')
end

M.is_enabled = function()
  return config.get_config().completion.enabled
end

M.prompt_code = completion.prompt_code

M.clear_context = context.clear_context

M.add_gitfiles = function()
  _G.gemini.yes_to_all = false
  local branch = vim.fn.system('git branch --show-current'):gsub('\n', '')
  local res = vim.fn.system('git ls-tree -r ' .. branch .. ' --name-only')
  local git_filenames = util.split_string(res, '\n')
  util.notify(vim.inspect(git_filenames), vim.log.levels.DEBUG)
  for _, file_name in ipairs(git_filenames) do
    file_name = vim.fn.fnamemodify(file_name, ':p')
    context.add_file(file_name)
  end
  _G.gemini.yes_to_all = false
end

return M
