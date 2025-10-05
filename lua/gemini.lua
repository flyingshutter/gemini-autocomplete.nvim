local config = require('gemini.config')
local api = require('gemini.api')
local util = require('gemini.util')
local context = require('gemini.context')
local completion = require('gemini.completion')

local M = {}

local function gemini_add_file(cmd_args)
  util.notify(vim.inspect(cmd_args.fargs), vim.log.levels.DEBUG)
  if #cmd_args.fargs < 2 then
    vim.notify('Error: Gemini add_file expected at least 1 filename', vim.log.levels.ERROR)
    return
  end
  for idx = 2, #cmd_args.fargs do
    local file_name = vim.fn.fnamemodify(vim.fn.expand(cmd_args.fargs[idx]), ":p")
    util.notify("file_name is " .. file_name, vim.log.levels.DEBUG)
    if file_name == "" then
      vim.notify('Gemini Error: Save file before adding to context', vim.log.levels.ERROR)
      return
    end

    util.notify("adding file " .. cmd_args.fargs[idx], vim.log.levels.DEBUG)
    context.add_file(file_name)
  end
  util.notify(cmd_args.fargs[2], vim.log.levels.DEBUG)
end

M.setup = function(opts)
  if not vim.fn.executable('curl') then
    vim.notify("Gemini: Could not find executable: 'curl'", vim.log.levels.ERROR)
    return
  end

  if not util.is_nvim_version_ge(0, 10, 0) then
    vim.notify('Gemini: neovim version may be too old', vim.log.levels.WARN)
    return
  end

  _G.gemini = {}

  vim.api.nvim_create_augroup('Gemini', { clear = true })

  config.set_config(opts)
  -- M.enabled = config.get_config().completion.enabled
  require('gemini.completion').setup()

  if config.get_config().general.mini_statusline then
    M.mini_statusline()
  end


  vim.api.nvim_create_autocmd('BufWritePost', {
    group = 'Gemini',
    callback = function(opts)
      local buf = opts.buf
      for watch_file_name, _ in pairs(context.context) do
        if watch_file_name == vim.api.nvim_buf_get_name(buf) then
          context.context[watch_file_name] = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end
      end
    end,
  })

  vim.api.nvim_create_user_command('Gemini', function(cmd_args)
    util.notify(vim.inspect(cmd_args), vim.log.levels.DEBUG)
    if cmd_args.args == 'choose_model' then
      M.choose_model()
    elseif cmd_args.fargs[1] == 'add_file' then
      gemini_add_file(cmd_args)
    elseif cmd_args.args == 'add_git_files' then
      M.add_gitfiles()
    elseif cmd_args.args == 'edit_context' then
      M.edit_context()
    elseif cmd_args.args == 'request_code' then
      completion.request_code()
    end
  end, {
    nargs = '+',
    complete = function(arglead, cmdline, cursorpos)
      return { 'choose_model', 'add_file', 'add_git_files', 'edit_context', 'request_code' }
    end,
    desc = 'Gemini commands: choose_model, add_file, add_gitfiles, edit_context, request_code'
  })
end

local function win_config(buf, opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend('force', {size = {60,20}, title = 'Unnamed Window'}, opts)
  local width = opts.size[1]
  local height = opts.size[2]
  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = 'rounded',
    title = opts.title .. '(q: abort, <Enter>: confirm)',
  }
end

M.edit_context = function ()
  local buf = vim.api.nvim_create_buf(false, true)
  local file_names = {}
  for file_name, _ in pairs(context.context) do
    table.insert(file_names, file_name)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, file_names)
  local height = math.min(vim.o.lines - 3, math.max(40, vim.api.nvim_buf_line_count(buf)))
  vim.api.nvim_open_win(buf, true, win_config(buf, {size = {90,height}, title = 'Edit files'}))

  vim.keymap.set('n', 'q', function()
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
       context.add_file(file_name)
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

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, available_models)
  local height = math.min(vim.o.lines - 3, vim.api.nvim_buf_line_count(buf))
  vim.api.nvim_open_win(buf, true, win_config(buf, { size = {40, height}, title = 'Choose Model'}))

  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Abort' })

  vim.keymap.set('n', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    config.set_config({ model = { model_id = line } })
    vim.api.nvim_win_close(0, false)
  end, { buffer = buf, desc = 'Confirm' })
end

M.mini_statusline = function()
  require('mini.statusline').config.content.active = function()
    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
    local git = MiniStatusline.section_git({ trunc_width = 40 })
    local diff = MiniStatusline.section_diff({ trunc_width = 75 })
    local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
    local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
    local filename = MiniStatusline.section_filename({ trunc_width = 140 })
    local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
    local location = MiniStatusline.section_location({ trunc_width = 75 })
    local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

    local gemini_model = require('gemini.config').get_config().model.model_id
    local pos = string.find(gemini_model, '-')
    local gemini_model_short = string.sub(gemini_model, pos + 1)
    local hl_gemini = 'PmenuMatchSel'
    if not require('gemini').is_enabled() then
      hl_gemini = 'DiffDelete'
    end

    return MiniStatusline.combine_groups({
      { hl = mode_hl, strings = { mode } },
      { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics, lsp } },
      '%<', -- Mark general truncate point
      { hl = 'MiniStatuslineFilename', strings = { filename } },
      '%=', -- End left alignment
      { hl = hl_gemini, strings = { gemini_model_short } },
      { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
      { hl = mode_hl, strings = { search, location } },
    })
  end
end

M.toggle_enabled = function()
  config.get_config().completion.enabled = not config.get_config().completion.enabled
  if config.get_config().completion.enabled then
    print('Gemini: Autocomplete enabled')
  else
    print('Gemini: Autocomplete disabled')
  end
  vim.api.nvim_command 'redraw!'
end

M.is_enabled = function()
  return config.get_config().completion.enabled
end

M.add_gitfiles = function()
  _G.gemini.yes_to_all = false
  local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  local res = vim.fn.system("git ls-tree -r " .. branch .. " --name-only")
  local git_filenames = util.split_string(res, '\n')
  util.notify(vim.inspect(git_filenames), vim.log.levels.DEBUG)
  for _, file_name in ipairs(git_filenames) do
    file_name = vim.fn.fnamemodify(file_name, ":p")
    context.add_file(file_name)
  end
  _G.gemini.yes_to_all = false
end

return M
