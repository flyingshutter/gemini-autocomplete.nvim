local api = require('gemini.api')
local util = require('gemini.util')

local M = {}

M.config = {
  general = {
    mini_statusline = nil,
  },
  model = {
    model_id = api.MODELS.GEMINI_2_5_FLASH_LITE,
    temperature = 1,
    -- top_k = 128,
    response_mime_type = 'text/plain',
  },
  request_code = {
    make_prompt = function(buf, pos, user_prompt)
      local context = require('gemini.context')
      return 'Your task is to write code as prompted by the user. Return only the code. I will give you:\n'
        .. '1) some important files as context\n'
        .. '2) the file we are currently editing, where the cursor position is marked by <cursor></cursor>\n'
        .. '3) the user prompt.\n\n'
        .. '1)\n'
        .. context.make_context_string()
        .. '\n\n'
        .. '2)\n'
        .. context.make_current_file_string(buf, pos)
        .. '\n\n'
        .. '3)\n'
        .. user_prompt
    end,
  },
  completion = {
    enabled = true,
    blacklist_filetypes = { 'help', 'qf', 'json', 'yaml', 'toml', 'xml' },
    blacklist_filenames = { '.env' },
    completion_delay = 800,
    insert_result_key = '<S-Tab>',
    move_cursor_end = true,
    can_complete = nil,
    get_system_text = function()
      return "You are a coding AI assistant that autocomplete user's code."
        .. '\n* Your task is to provide code suggestion at the cursor location marked by <cursor></cursor>.'
        .. '\n* Your response does not need to contain explaination.'
    end,
    make_prompt = function(buf, pos)
      local context = require('gemini.context')
      return 'Your task is to write code. Return only the code. I will give you:\n'
        .. '1) some important files as context\n'
        .. '2) the file we are currently editing, where the cursor position is marked by <cursor></cursor>\n'
        .. 'Return the most likely completion at the cursor\n\n'
        .. '1)\n'
        .. context.make_context_string()
        .. '\n\n'
        .. '2)\n'
        .. context.make_current_file_string(buf, pos)
        .. '\n\n'
    end,
  },
}

M.set_config = function(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

M.get_config = function()
  return M.config
end

M.get_gemini_generation_config = function()
  return {
    temperature = M.get_config().model.temperature,
    -- topK = M.get_config().model.top_k,
    response_mime_type = M.get_config().model.response_mime_type,
  }
end

return M
