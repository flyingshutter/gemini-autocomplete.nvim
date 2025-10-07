# gemini-autocomplete.nvim
Codebase aware autocomplete and code prompting using Gemini.  

https://github.com/user-attachments/assets/2ff7616e-8895-4b8b-93af-6c64937cd3aa

## Features 
- Autocomplete (std key: Shift+Tab)
- Prompt for code insertion
- Context aware: Manage known files manually or let git do the job (if manual, try stuff like `:r !ls *.py` or `:r !find . -name *.lua` in the context editor)
- Quickly switch completion on and off
- Show model and state in statusline (using mini.statusline)
- supports gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite, gemini-2.0-flash, gemini-2.0-flash-lite


## Installation
Make sure you have `curl` installed and your Api key in the environment variables. 
Optional: have `git`
```
sudo apt install curl
export GEMINI_API_KEY="<your API key here>"
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ 'flyingshutter/gemini-autocomplete.nvim', opts = {} }
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use { 'flyingshutter/gemini-autocomplete.nvim', opts = {} }
```
run `nvim` and `:checkhealth gemini-autocomplete`

## Vim Commands
```vim
:GeminiAutocomplete prompt_code   "asks the user for a prompt and inserts the generated output under the cursor
:GeminiAutocomplete choose_model  "opens a popup window that lets you choose the active gemini model
:GeminiAutocomplete edit_context  "opens a popup window that lets you edit the list of files in the code context
:GeminiAutocomplete add_file <file1> [<file2> ...]    "add file(s) to code context (% also works)
:GeminiAutocomplete remove_file <file1> [<file2> ...] "add file(s) to code context
:GeminiAutocomplete clear_context "clears the file context
:GeminiAutocomplete add_git_files "if your project is versioned, adds all git handled files to the code context
```

## Example config
* Show model and status info in mini.statusline (Install separately from [mini.nvim](https://github.com/nvim-mini/mini.nvim))
* Define some keymaps
* Disable autocompletion on start
```lua
  {
    'flyingshutter/gemini-autocomplete.nvim/',
    config = function()
      local gemini = require 'gemini-autocomplete'
      gemini.setup {
        general = { make_statusline = require('gemini-autocomplete.external').make_mini_statusline },
        model = {
          model_id = require('gemini-autocomplete.api').MODELS.GEMINI_2_5_FLASH_LITE,
        },
        -- I like to have it disabled on startup and manually activate when needed (free tier user, quota matters)
        completion = { enabled = false },
      }

      require('gemini-autocomplete.external').make_mini_statusline() -- show gemini in statusline and indicate (en/dis)abled

      vim.keymap.set('n', '<leader>gt', gemini.toggle_enabled, { desc = '[G]emini [T]oggle Autocompletion' })
      vim.keymap.set('n', '<leader>gg', gemini.add_gitfiles, { desc = '[G]emini add [G]itfiles' })
      vim.keymap.set('n', '<leader>ge', gemini.edit_context, { desc = '[G]emini [E]dit Context' })
      vim.keymap.set('n', '<leader>gp', gemini.prompt_code, { desc = '[G]emini [P]rompt Code' })
      vim.keymap.set('n', '<leader>gc', gemini.clear_context, { desc = '[G]emini [C]lear Context' })
      vim.keymap.set('n', '<leader>gm', gemini.choose_model, { desc = '[G]emini Choose [M]odel' })
    end,
  },

```

## Default Settings
```lua
opts = {
  model = {
    model_id = api.MODELS.GEMINI_2_5_FLASH_LITE,
    temperature = 1,
    response_mime_type = 'text/plain',
    get_system_text = function()
      return "You are a coding AI assistant that autocomplete user's code."
        .. '\n* Your task is to provide code suggestion at the cursor location marked by <cursor></cursor>.'
        .. '\n* Your response does not need to contain explaination.'
    end,
  },
  prompt_code = {
    make_prompt = function(buf, pos, user_prompt)
      local context = require('gemini-autocomplete.context')
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
    blacklist_filetypes = { 'help', 'qf', 'yaml', 'toml', 'xml' },
    blacklist_filenames = { '.env' },
    completion_delay = 800,
    insert_result_key = '<S-Tab>',
    move_cursor_end = true,
    can_autocomplete = function()
      return vim.fn.pumvisible() ~= 1
    end,
    make_prompt = function(buf, pos)
      local context = require('gemini-autocomplete.context')
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
```
# Thanks
This is a heavily altered fork of https://github.com/kiddos/gemini.nvim







