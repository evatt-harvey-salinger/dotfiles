return {
  'Vigemus/iron.nvim',
  -- Load when any REPL key is pressed (lazy.nvim will use these to lazy-load the plugin)
  keys = {
    { '<leader>rn', desc = 'REPL: [R]un [N]ext - Run block and go to next' },
    { '<leader>rb', desc = 'REPL: [R]un [B]lock - Run current code block' },
    { '<leader>ru', desc = 'REPL: [R]un [U]ntil - Run from start until the cursor' },
    { '<leader>rR', desc = 'REPL: [R]estart [R]epl - Restart the REPL for this buffer' },
    { '<leader>rr', desc = 'REPL: [R]epl [R]eopen - Toggle / create REPL window' },
    { '<leader>rl', desc = 'REPL: [R]un [L]ine - Send the current line to REPL' },
    { '<leader>rf', desc = 'REPL: [R]un [F]ile - Send the entire file to REPL' },
    { '<leader>rv', desc = 'REPL: [R]epl [V]isual - Send the current visual selection' },
    { '<leader>ra', desc = 'REPL: [R]epl [A]ll - Select/run the whole cell or buffer' },
    { '<leader>rc', desc = 'REPL: [R]epl [C]ommand/Motion - Send a motion or command to REPL' },
  },
  config = function()
    local iron = require('iron.core')
    local view = require('iron.view')
    local common = require('iron.fts.common')

    iron.setup {
      config = {
        -- keep repls ephemeral
        scratch_repl = true,

        -- some sensible repl defs; adjust to taste
        repl_definition = {
          sh = { command = { 'zsh' } },
          python = {
            -- prefer system python; change to ipython if you like that behaviour
            command = { 'python3' },
            format = common.bracketed_paste_python,
            block_dividers = { '# %%', '#%%' },
          },
        },

        -- Make the repl buffer have the same filetype as the source buffer
        repl_filetype = function(_, ft) return ft end,

        -- Open repl in a right-side vertical split with 40 columns
        repl_open_cmd = view.split.vertical.rightbelow(40),
      },

      -- Map iron's named maps to your requested <leader>r... prefix so they don't conflict
      keymaps = {
        toggle_repl = '<leader>rr',
        restart_repl = '<leader>rR',

        -- Sending helpers (these keys match your VS Code mappings where possible)
        send_code_block_and_move = '<leader>rn',
        send_code_block = '<leader>rb',
        send_until_cursor = '<leader>ru',
        send_line = '<leader>rl',
        send_file = '<leader>rf',
        visual_send = '<leader>rv',
        send_mark = '<leader>rm',

        -- small helpers
        cr = '<leader>r<CR>',
        interrupt = '<leader>r<C-c>',
        exit = '<leader>rq',
        clear = '<leader>rcl',
      },

      highlight = { italic = true },
      ignore_blank_lines = true,
    }

    -- Helpful commands to focus/hide the REPL (no conflict with send keys above)
    vim.keymap.set('n', '<leader>rF', '<cmd>IronFocus<cr>', { desc = 'REPL: [R]epl [F]ocus - Focus the REPL window' })
    vim.keymap.set('n', '<leader>rH', '<cmd>IronHide<cr>', { desc = 'REPL: [R]epl [H]ide - Hide the REPL window' })
  end,
}
