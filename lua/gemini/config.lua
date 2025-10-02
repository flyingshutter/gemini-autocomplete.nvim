local api = require('gemini.api')
local util = require('gemini.util')

local M = {}

local default_config = {
  model = {
    model_id = api.MODELS.GEMINI_2_5_FLASH_LITE,
    temperature = 0.10,
    top_k = 128,
    response_mime_type = 'text/plain',
  },
  completion = {
    enabled = true,
    blacklist_filetypes = { 'help', 'qf', 'json', 'yaml', 'toml', 'xml' },
    blacklist_filenames = { '.env' },
    completion_delay = 800,
    insert_result_key = '<S-Tab>',
    move_cursor_end = true,
    can_complete = function()
      return vim.fn.pumvisible() ~= 1
    end,
    get_system_text = function()
      return "You are a coding AI assistant that autocomplete user's code."
        .. '\n* Your task is to provide code suggestion at the cursor location marked by <cursor></cursor>.'
        .. '\n* Your response does not need to contain explaination.'
    end,
    get_prompt = function(bufnr, pos)
      local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
      local prompt = 'Below is the content of a %s file `%s`:\n'
        .. '```%s\n%s\n```\n\n'
        .. 'Suggest the most likely code at <cursor></cursor>.\n'
        .. 'Wrap your response in ``` ```\n'
        .. 'eg.\n```\n```\n\n'
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local line = pos[1]
      local col = pos[2]
      local target_line = lines[line]
      if target_line then
        lines[line] = target_line:sub(1, col) .. '<cursor></cursor>' .. target_line:sub(col + 1)
      else
        return nil
      end
      local code = vim.fn.join(lines, '\n')
      local abs_path = vim.api.nvim_buf_get_name(bufnr)
      local filename = vim.fn.fnamemodify(abs_path, ':.')
      prompt = string.format(prompt, filetype, filename, filetype, code)
      return prompt
    end,
  },
}

M.set_config = function(opts)
  M.config = vim.tbl_deep_extend('force', {}, default_config, opts or {})
end

M.get_config = function(keys)
  return vim.tbl_get(M.config, unpack(keys))
end

M.get_gemini_generation_config = function()
  return {
    temperature = M.get_config({ 'model', 'temperature' }),
    topK = M.get_config({ 'model', 'top_k' }),
    response_mime_type = M.get_config({ 'model', 'response_mime_type' }),
  }
end

return M
