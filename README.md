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

## User commands
:Gemini add_file
:Gemini add_git_file
:Gemini choose_model
:Gemini clear_contex
:Gemini edit_context
:Gemini prompt_code
:Gemini remove_file

## Example config
Use mini.statusline from [mini.nvim](https://github.com/nvim-mini/mini.nvim)
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
        completion = { enabled = false },
      }

      vim.keymap.set('n', '<leader>ac', gemini.toggle_enabled, { desc = 'Toggle Gemini [a]uto[c]ompletion' })
      vim.keymap.set('n', '<leader>af', gemini.add_gitfiles, { desc = 'Gemini add Git[f]iles' })

      require('gemini.external').make_mini_statusline()
    end,
  },
```

## Default Setting
```lua
```
