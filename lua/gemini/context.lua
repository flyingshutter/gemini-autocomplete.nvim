local watchlist = {
}

local M = {}
M.context = {}

M.add_file = function(file_name)
  if not M.context[file_name] then
    M.context[file_name] =  vim.fn.readfile(file_name)
  end
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


