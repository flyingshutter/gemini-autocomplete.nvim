# gemini.nvim
Codebase aware autocomplete and code prompting using Gemini.  

## Features 
- Choose model (gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite, gemini-2.0-flash, gemini-2.0-flash-lite)
- Context aware: Manage known files manually or let git do the job
- switch completion on and off
- show model and state in statusline (using mini.statusline)


## Installation
Make sure you have `curl` installed and your Api key in the environment variables. 
Optional: have `git`
```
sudo apt install curl
export GEMINI_API_KEY="<your API key here>"
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ 'flyingshutter/gemini.nvim', opts = {} }
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use { 'flyingshutter/gemini.nvim', opts = {} }
```
## User interface
```vim
- :Gemini prompt_code   "asks the user for a prompt and inserts the generated output under the cursor
- :Gemini choose_model  "opens a popup window that lets you choose the active gemini model
- :Gemini edit_context  "opens a popup window that lets you edit the list of files in the code context
- :Gemini add_file <file1> [<file2> ...]    "add file(s) to code context (% also works)
- :Gemini remove_file <file1> [<file2> ...] "add file(s) to code context
- :Gemini clear_context "clears the file context
- :Gemini add_git_files "if your project is versioned, adds all git handled files to the code context
```

## Example config
* Show model and status info in mini.statusline from [mini.nvim](https://github.com/nvim-mini/mini.nvim)
* Define some keymaps
* Disable autocompletion on start
```lua
  {
    'flyingshutter/gemini.nvim/',
    config = function()
      local gemini = require 'gemini'
      gemini.setup {
        general = { make_statusline = require('gemini.external').make_mini_statusline },
        model = {
          model_id = require('gemini.api').MODELS.GEMINI_2_5_FLASH_LITE,
        },
        -- I like to have it disabled on startup and manually activate when needed (free tier user, quota matters)
        completion = { enabled = false },
      }

      require('gemini.external').make_mini_statusline() -- show gemini in statusline and indicate (en/dis)abled

      vim.keymap.set('n', '<leader>gt', gemini.toggle_enabled, { desc = '[G]emini [T]oggle Autocompletion' })
      vim.keymap.set('n', '<leader>gg', gemini.add_gitfiles, { desc = '[G]emini add [G]itfiles' })
      vim.keymap.set('n', '<leader>ge', gemini.edit_context, { desc = '[G]emini [E]dit Context' })
      vim.keymap.set('n', '<leader>gp', gemini.prompt_code, { desc = '[G]emini [P]rompt Code' })
      vim.keymap.set('n', '<leader>gc', gemini.clear_context, { desc = '[G]emini [C]lear Context' })
      vim.keymap.set('n', '<leader>gm', gemini.choose_model, { desc = '[G]emini Choose [M]odel' })
    end,
  },

```

## Default Setting
```lua
```
