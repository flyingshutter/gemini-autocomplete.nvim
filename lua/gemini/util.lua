local M = {}

M.debounce = function(callback, timeout)
  local timer = nil
  local f = function(...)
    local t = { ... }
    local handler = function()
      callback(unpack(t))
    end

    if timer ~= nil then
      timer:stop()
    end
    timer = vim.defer_fn(handler, timeout)
  end
  return f
end

M.is_blacklisted = function(blacklist, filetype)
  for _, ft in ipairs(blacklist) do
    if string.find(filetype, ft, 1, true) ~= nil then
      return true
    end
  end
  return false
end

M.strip_code = function(text)
  local code_blocks = {}
  if not text then
    return code_blocks
  end

  local pattern = '```(%w+)%s*(.-)%s*```'
  for _, code_block in text:gmatch(pattern) do
    table.insert(code_blocks, code_block)
  end
  if #code_blocks == 0 then
    return { text }
  end
  return code_blocks
end

M.is_nvim_version_ge = function(major, minor, patch)
  local v = vim.version()
  if v.major > major then
    return true
  elseif v.major == major then
    if v.minor > minor then
      return true
    elseif v.minor == minor and v.patch >= patch then
      return true
    end
  end
  return false
end

M.notify = function(msg, level, opts)
  level = level or vim.log.levels.INFO
  opts = opts or nil
  local notify_level = vim.g.notify_level or vim.log.levels.INFO

  if level >= notify_level then
    vim.notify(msg, level, opts)
  end
end

M.split_string = function(inputstr, sep)
  if sep == nil then
    sep = '%s'
  end
  local t = {}
  for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    table.insert(t, str)
  end
  return t
end

M.is_text_file = function(filepath)
 if vim.fn.filereadable(filepath) == 0 then
   return false -- File does not exist or is not readable
 end

 local f = io.open(filepath, "rb")
 if not f then
   return false -- Could not open file (e.g., permissions)
 end

 local content = f:read(1024)
 f:close()

 if not content then
   return true -- Empty files are generally considered text files
 end

 -- 4. Check for the presence of a null byte ('\0')
 -- Binary files almost always contain null bytes. Text files generally do not.
 return not content:find("\0", 1, true)
end

return M
