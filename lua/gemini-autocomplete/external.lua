local config = require('gemini-autocomplete.config')

local M = {}

M.make_mini_statusline = function()
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

    local gemini_model = require('gemini-autocomplete.config').get_config().model.model_id
    local pos = string.find(gemini_model, '-')
    local gemini_model_short = string.sub(gemini_model, pos + 1)

    local colors = config.get_config().external.mini_statusline
    local hl_gemini = colors.hl_disabled
    if require('gemini-autocomplete').is_enabled() then
      hl_gemini = colors.hl_enabled
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

return M
