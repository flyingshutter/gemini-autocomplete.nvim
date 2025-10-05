local util = require('gemini.util')

local M = {}
M.context = {}

M.add_file = function(file_name, opts)
  opts = opts or {}
  if M.context[file_name] then
    vim.notify(string.format("Gemini: File already in context, skipping: '%s'", file_name), vim.log.levels.INFO)
    return
  end
  -- user has to confirm files bigger 1MB
  local file_size = vim.fn.getfsize(file_name)
  if file_size == -1 then
    util.notify(string.format("Gemini: File not found: '%s'", file_name), vim.log.levels.ERROR)
    return
  end
  if file_size > math.pow(2, 20) then
    local decision = nil
    if not _G.gemini.yes_to_all then
      decision = vim.fn.input('\nFile ' .. file_name .. '\n is bigger than 1MiB, really load it? [y]es, [n]o, [a]ll:  ')
      print('\n')
      if decision == 'a' or decision == 'A' then
        _G.gemini.yes_to_all = true
      end
    end
    if not (decision == 'y' or decision == 'Y' or _G.gemini.yes_to_all) then
      return
    end
  end
  -- load file and reject if it is binary
  if not util.is_text_file(file_name) then
    vim.notify(string.format("Gemini: Rejected binary file: '%s'", file_name), vim.log.levels.ERROR)
    return
  end
  -- add file to context
  local lines_table = vim.fn.readfile(file_name)
  M.context[file_name] = lines_table
  vim.notify("Gemini: Adding file: '" .. file_name .. "'", vim.log.levels.INFO)
end

M.make_context_string = function(active_buf)
  local context_string = ''
  for file_name, line_list in pairs(M.context) do
    local file_content = table.concat(line_list, '\n')
    local file_context_string = 'Filename: ' .. file_name .. '\n' .. file_content .. '\n'
    context_string = context_string .. file_context_string
  end
  return context_string
end

M.make_current_file_string = function(buf, pos)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local line = pos[1]
  local col = pos[2]
  local target_line = lines[line]
  if target_line then
    lines[line] = target_line:sub(1, col) .. '<cursor></cursor>' .. target_line:sub(col + 1)
  else
    return nil
  end

  local code = vim.fn.join(lines, '\n')
  local abs_path = vim.api.nvim_buf_get_name(buf)
  local filename = vim.fn.fnamemodify(abs_path, ':.')

  return 'Filename: ' .. filename .. '\n' .. code .. '\n'
end

return M
