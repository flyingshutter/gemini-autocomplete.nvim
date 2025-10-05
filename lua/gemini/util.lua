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

M.get_list_differences = function (old_list, new_list)
  local added = {}
  local removed = {}

  -- Create a set (using a table) for efficient lookup of values in the old_list
  local old_values_set = {}
  for _, value in ipairs(old_list) do
    old_values_set[value] = (old_values_set[value] or 0) + 1 -- Count occurrences if duplicates are possible
  end

  -- Find added values (present in new_list but not in old_list)
  -- And decrement count for values present in both
  for _, new_value in ipairs(new_list) do
    if old_values_set[new_value] and old_values_set[new_value] > 0 then
      -- Value exists in old_list, mark it as "seen" by decrementing
      old_values_set[new_value] = old_values_set[new_value] - 1
    else
      -- Value is not in old_list, or all its occurrences have been matched
      table.insert(added, new_value)
    end
  end

  -- Any remaining values in old_values_set are the "removed" ones
  for old_value, count in pairs(old_values_set) do
    for i = 1, count do
      table.insert(removed, old_value)
    end
  end

  return added, removed
end

M.delete_strings_starting_with_backticks = function(string_list)
    local cleaned_list = {}
    local pattern = "^`" -- Regex: starts with a backtick

    for _, str in ipairs(string_list) do
        -- If string.match returns nil, it means the pattern was not found,
        -- so the string does NOT start with a backtick.
        if not string.match(str, pattern) then
            table.insert(cleaned_list, str)
        end
    end

    return cleaned_list
 end

return M
