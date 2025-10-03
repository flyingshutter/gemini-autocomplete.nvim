local util = require('gemini.util')

local watchlist = {
}

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
  if file_size > math.pow(2,20) then
    local decision = nil
    if not _G.gemini.yes_to_all then
      decision = vim.fn.input("\nFile " .. file_name .. "\n is bigger than 1MiB, really load it? [y]es, [n]o, [a]ll:  ")
      print("\n")
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
    vim.notify(string.format("Gemini: Rejected binary file: '%s'", file_name), vim.log.levels.INFO)
    return
  end
  -- add file to context
  local lines_table =  vim.fn.readfile(file_name)
  M.context[file_name] = lines_table
  vim.notify(string.format("Gemini: Adding file of size %s: '", file_size) .. file_name .. "'", vim.log.levels.INFO)
end

M.make_context_string = function(active_buf)
  local context_string = ""
  for file_name, line_list in pairs(M.context) do
    local file_content = table.concat(line_list, '\n')
    local file_context_string = "Filename: " .. file_name .. "\nContent:\n" .. file_content .. "\n\n"
    context_string = context_string .. file_context_string
  end
  return context_string
end
vim.api.nvim_create_augroup('astest', { clear = true })

vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'astest',
  callback = function(opts)
    local buf = opts.buf
    -- TODO: replace watchlist with M.context and test write on save:
    for _, watch_file_name in ipairs(watchlist) do
      -- print( watch_file_name .. "  " .. vim.api.nvim_buf_get_name(buf))
      if watch_file_name == vim.api.nvim_buf_get_name(buf) then
        -- print("Adding file " .. vim.api.nvim_buf_get_name(buf) .. " to context")
        M.context[watch_file_name] = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      end
    end
    -- print(vim.inspect(M))
    -- print( M.make_context_string())
  end,
})

-- M.add_file('/home/sca04245/as/Projekte/2025-09-28_nvim_plugins/gemini.nvim/d1.txt')
-- M.add_file('/home/sca04245/as/Projekte/2025-09-28_nvim_plugins/gemini.nvim/d2.txt')
return M


