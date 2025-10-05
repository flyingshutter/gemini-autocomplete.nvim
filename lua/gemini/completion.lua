local config = require('gemini.config')
local util = require('gemini.util')
local api = require('gemini.api')
local context = require('gemini.context')

local M = {}

local gemini_context = {
  namespace_id = nil,
  completion = nil,
}

M.setup = function()
  local blacklist_filetypes = config.get_config().completion.blacklist_filetypes
  local blacklist_filenames = config.get_config().completion.blacklist_filenames

  gemini_context.namespace_id = vim.api.nvim_create_namespace('gemini_completion')

  vim.api.nvim_create_autocmd('CursorMovedI', {
    group = 'Gemini',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local filetype = vim.api.nvim_get_option_value('filetype', { buf = buf })
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t')
      if util.is_blacklisted(blacklist_filetypes, filetype) or util.is_blacklisted(blacklist_filenames, filename) then
        return
      end
      M.gemini_complete()
    end,
  })

  vim.api.nvim_set_keymap('i', config.get_config().completion.insert_result_key, '', {
    callback = function()
      M.insert_completion_result()
    end,
  })
end

M.request_code = function ()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)

  local user_prompt = vim.fn.input("Prompt please: ")
  local user_text = config.get_config().request_code.make_prompt(buf, pos, user_prompt)
  util.notify(user_text, vim.log.levels.DEBUG)

  local system_text = config.get_config().completion.get_system_text()
  local model_id = config.get_config().model.model_id
  local generation_config = config.get_gemini_generation_config()

  api.gemini_generate_content(user_text, system_text, model_id, generation_config, function(response_lines)
    vim.schedule(function()
      local current_pos = vim.api.nvim_win_get_cursor(win)
      if current_pos[1] ~= pos[1] or current_pos[2] ~= pos[2] then
        util.notify("Cursor moved since request. Did not insert result", vim.log.levels.WARN)
        return
      end
      util.notify("Done. Result inserted below cursor.", vim.log.levels.INFO)
      vim.api.nvim_buf_set_lines(buf, pos[1], pos[1], false, response_lines)
    end)
  end)
end

M._gemini_complete = function()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_cursor(win)

  local user_text = config.get_config().completion.make_prompt(buf, pos)
  util.notify(user_text, vim.log.levels.DEBUG)

  local system_text = config.get_config().completion.get_system_text()
  local model_id = config.get_config().model.model_id
  local generation_config = config.get_gemini_generation_config()

  api.gemini_generate_content(user_text, system_text, model_id, generation_config, function(response_lines)
    vim.schedule(function()
      local model_response = vim.fn.join(response_lines, '\n')
      M.show_completion_result(model_response, win, pos)
    end)
  end)
end

local can_complete = config.get_config().completion.can_complete
or function()
  return vim.fn.pumvisible() ~= 1
end

M.gemini_complete = util.debounce(function()
  -- if not require('gemini').enabled then
  if not require'gemini.config'.config.completion.enabled then
    return
  end

  if vim.fn.mode() ~= 'i' then
    return
  end

  if not can_complete() then
    return
  end

  local model_id = config.get_config().model.model_id
  print(string.format('-- %s complete --', model_id))
  M._gemini_complete()
end, config.get_config().completion.completion_delay)

M.show_completion_result = function(result, win_id, pos)
  local win = vim.api.nvim_get_current_win()
  if win ~= win_id then
    return
  end

  local current_pos = vim.api.nvim_win_get_cursor(win)
  if current_pos[1] ~= pos[1] or current_pos[2] ~= pos[2] then
    return
  end

  if vim.fn.mode() ~= 'i' then
    return
  end

  if not can_complete() then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local options = {
    id = 1,
    virt_text = {},
    virt_lines = {},
    hl_mode = 'combine',
    virt_text_pos = 'inline',
  }

  local content = result:match('^%s*(.-)%s*$')
  for i, l in pairs(vim.split(content, '\n')) do
    if i == 1 then
      options.virt_text[1] = { l, 'Comment' }
    else
      options.virt_lines[i - 1] = { { l, 'Comment' } }
    end
  end
  local row = pos[1]
  local col = pos[2]
  local id = vim.api.nvim_buf_set_extmark(bufnr, gemini_context.namespace_id, row - 1, col, options)

  gemini_context.completion = {
    content = content,
    row = row,
    col = col,
    bufnr = bufnr,
  }

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertLeavePre' }, {
    buffer = bufnr,
    callback = function()
      gemini_context.completion = nil
      vim.api.nvim_buf_del_extmark(bufnr, gemini_context.namespace_id, id)
      vim.api.nvim_command('redraw')
    end,
    once = true,
  })
end

M.insert_completion_result = function()
  if not gemini_context.completion then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not gemini_context.completion.bufnr == bufnr then
    return
  end

  local row = gemini_context.completion.row - 1
  local col = gemini_context.completion.col
  local first_line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
  local lines = vim.split(gemini_context.completion.content, '\n')
  lines[1] = string.sub(first_line, 1, col) .. lines[1] .. string.sub(first_line, col + 1)
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, lines)

  if config.get_config().completion.move_cursor_end == true then
    local new_row = row + #lines
    local new_col = #vim.api.nvim_buf_get_lines(0, new_row - 1, new_row, false)[1]
    vim.api.nvim_win_set_cursor(0, { new_row, new_col })
  end

  gemini_context.completion = nil
end

return M
