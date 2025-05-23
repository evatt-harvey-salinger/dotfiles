-- lua/custom/plugins/iron.lua
return {
  "Vigemus/iron.nvim",
  ft = { "python", "sh" },
  dependencies = {
    -- Optional: if you want to use a specific icon set for Neovim,
    -- ensure your terminal and font support it.
    -- "nvim-tree/nvim-web-devicons", -- For filetype icons (if you customize repl_filetype)
  },
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    local common = require("iron.fts.common") -- For bracketed_paste_python

    iron.setup({
      -- Configuration options
      config = {
        -- Highlights the last sent block with bold.
        -- You can set this to false to disable, or use a different highlight group.
        highlight_last = "IronLastSent",

        -- Toggling behavior for the REPL window.
        -- Options:
        --   require("iron.visibility").toggle (default: opens/closes window)
        --   require("iron.visibility").single (ensures window exists and shows it)
        --   require("iron.visibility").focus (moves focus to the REPL window)
        visibility = require("iron.visibility").toggle,

        -- Scope of the REPL.
        -- Options:
        --   require("iron.scope").path_based (default: one REPL per current working directory)
        --   require("iron.scope").tab_based (one REPL per tab)
        --   require("iron.scope").singleton (one REPL per filetype globally)
        scope = require("iron.scope").path_based,

        -- Whether the REPL buffer is a "throwaway" (scratch) buffer or not.
        -- true: REPL buffer won't appear in buffer list, won't be saved.
        -- false: REPL buffer will be a normal buffer.
        scratch_repl = true,

        -- Automatically closes the REPL window when the underlying process exits.
        close_window_on_exit = true,

        -- REPL definitions for different filetypes.
        repl_definition = {
          python = {
            -- command = { "python3" }, -- For standard Python REPL
            command = { "ipython", "--no-autoindent" }, -- For IPython
            format = common.bracketed_paste_python, -- Handles multi-line pastes correctly
            -- Optional: Define block dividers for sending code blocks (e.g., for # %%)
            block_dividers = { "# %%", "#%%" },
          },
          sh = {
            command = { "bash" }, -- or "zsh", "fish", etc.
          },
          -- Add other language REPLs as needed
          -- lua = {
          --   command = {"lua"}
          -- }
        },

        -- Function to set the filetype of the REPL buffer.
        -- bufnr: buffer ID of the REPL
        -- ft: filetype of the language being used for the REPL
        repl_filetype = function(bufnr, ft)
          -- return "iron_repl" -- You can set a custom filetype for syntax highlighting or statusline
          return ft -- Or simply use the language's filetype
        end,

        -- How the REPL window will be displayed.
        -- Examples:
        --   view.bottom(40)          -- Floating window at the bottom, 40 lines high
        --   view.right("30%")        -- Floating window on the right, 30% of editor width
        --   view.split.vertical.botright(80) -- Vertical split, bottom right, 80 columns
        --   view.split.botright(15)  -- Horizontal split, bottom right, 15 lines
        -- repl_open_cmd = view.bottom(40),
        repl_open_cmd = view.split.vertical.rightbelow("50%"),
        -- repl_open_cmd = "belowright 15 split", -- Alternative: Vim command string

        -- If the REPL buffer is listed in `ls` or buffer explorers.
        buflisted = false,

        -- Ignore blank lines when sending visual selections.
        ignore_blank_lines = true,
      },

      -- Keymappings for Iron.nvim.
      -- Set these to your preferred shortcuts.
      keymaps = {
        send_motion = "<leader>sc", -- Send code based on a motion
        visual_send = "<leader>sc", -- Send visually selected code (uses same mapping in visual mode)
        send_file = "<leader>sf", -- Send the entire file
        send_line = "<leader>sl", -- Send the current line
        send_until_cursor = "<leader>su", -- Send from start of buffer to cursor
        send_mark = "<leader>sm", -- Send code within the last `IronMark`
        -- send_paragraph = "<leader>sp", -- Send current paragraph (requires uncommenting in core.lua or custom setup)
        send_code_block = "<leader>sb", -- Send code block (if block_dividers are defined)
        send_code_block_and_move = "<leader>sn", -- Send code block and move to next

        mark_motion = "<leader>mc", -- Mark code based on a motion
        mark_visual = "<leader>mc", -- Mark visually selected code
        remove_mark = "<leader>md", -- Remove the last `IronMark`

        cr = "<leader>s<cr>", -- Send a carriage return to the REPL
        interrupt = "<leader>s<space>", -- Send an interrupt signal (Ctrl-C)
        exit = "<leader>sq", -- Send command to exit/close the REPL (Ctrl-D)
        clear = "<leader>cl", -- Send command to clear the REPL screen (Ctrl-L)

        toggle_repl = "<leader>rr", -- Toggle the REPL window open/closed
        restart_repl = "<leader>rR", -- Restart the REPL
        -- If repl_open_cmd is a table with multiple commands:
        -- toggle_repl_with_cmd_1 = "<leader>rv",
        -- toggle_repl_with_cmd_2 = "<leader>rh",
      },

      -- Highlight group for the `highlight_last` feature.
      -- For available options, check :h nvim_set_hl
      highlight = {
        italic = true,
        bold = true,
        -- fg = "#somecolor",
        -- bg = "#anothercolor",
      },
    })

    -- Optional: Additional commands or keymaps
    -- vim.keymap.set('n', '<leader>rf', '<cmd>IronFocus<cr>', { desc = "Iron: Focus REPL" })
    -- vim.keymap.set('n', '<leader>rh', '<cmd>IronHide<cr>', { desc = "Iron: Hide REPL" })
  end,
}
