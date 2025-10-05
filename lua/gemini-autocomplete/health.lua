local M = {}

M.check = function()
  vim.health.start('Gemini-autocomplete report')

  if vim.fn.executable('curl') == 1 then
    vim.health.ok("Found executable: 'curl'")
  else
    vim.health.error("Could not find executable: 'curl'")
  end

  if vim.fn.executable('git') == 1 then
    vim.health.ok("Found executable: 'git'")
  else
    vim.health.warn("Could not find executable: 'git'. ':Gemini-autocomplete add_git_files will not work'")
  end

  local gemini_api_key = os.getenv('GEMINI_API_KEY')
  if gemini_api_key and type(gemini_api_key) == 'string' then
    vim.health.ok('`GEMINI_API_KEY` is in environment variables.')
  else
    vim.health.error('`GEMINI_API_KEY` is not in environment variables')
  end
end

return M
