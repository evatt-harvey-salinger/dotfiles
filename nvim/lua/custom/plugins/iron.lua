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
    local iron = require 'iron.core'
    local view = require 'iron.view'
    local common = require 'iron.fts.common'

    iron.setup {
      config = {
        -- keep repls ephemeral
        scratch_repl = true,

        -- some sensible repl defs; adjust to taste
        repl_definition = {
          sh = { command = { 'zsh' } },
          python = {
            -- prefer system python; change to ipython if you like that behaviour
            command = { 'ipython', '--no-autoindent' },
            format = common.bracketed_paste,
            block_dividers = { '# %%', '#%%' },
          },
        },

        -- Make the repl buffer have the same filetype as the source buffer
        repl_filetype = function(_, ft)
          return ft
        end,

        -- Open repl in a right-side vertical split with 40 columns
        -- repl_open_cmd = view.split.vertical.rightbelow '40%',
        repl_open_cmd = view.split.horizontal.rightbelow '30%',
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

    -- Implement a comment-stripping filter with an optional treesitter backend.
    -- We try to use the treesitter-based filter (lua/custom/iron_filter.lua) when
    -- available; otherwise we fall back to the original lightweight heuristic.
    local has_ts_filter, ts_filter = pcall(require, 'custom.iron_filter')

    local comment_markers = {
      python = { '#' },
      sh = { '#' },
      bash = { '#' },
      zsh = { '#' },
      lua = { '--' },
      javascript = { '//' },
      javascriptreact = { '//' },
      typescript = { '//' },
      typescriptreact = { '//' },
      c = { '//', '/*', '*/' },
      cpp = { '//', '/*', '*/' },
      java = { '//', '/*', '*/' },
      rust = { '//', '/*', '*/' },
      go = { '//', '/*', '*/' },
      ruby = { '#' },
      r = { '#' },
      php = { '//', '/*', '*/' },
    }

    local function escape_for_pattern(s)
      return s:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
    end

    -- Naive block comment stripper handling /* ... */ style comments (fallback)
    local function strip_block_comments(text_lines, open_marker, close_marker)
      local out = {}
      local in_block = false
      for _, line in ipairs(text_lines) do
        if in_block then
          if line:find(escape_for_pattern(close_marker), 1, true) then
            local _, e = line:find(escape_for_pattern(close_marker), 1, true)
            local rest = line:sub(e + 1)
            if rest:match '%S' then
              table.insert(out, rest)
            end
            in_block = false
          end
        else
          local si, ei = line:find(escape_for_pattern(open_marker), 1, true)
          if si then
            local ci, ce = line:find(escape_for_pattern(close_marker), ei + 1, true)
            if ci then
              -- open and close on same line, keep parts outside
              local before = line:sub(1, si - 1)
              local after = line:sub(ce + 1)
              -- preserve leading indentation; remove only trailing spaces
              local merged = (before .. ' ' .. after):gsub('%s+$', '')
              if merged:match '%S' then
                table.insert(out, merged)
              end
            else
              local before = line:sub(1, si - 1)
              if before:match '%S' then
                table.insert(out, before)
              end
              in_block = true
            end
          else
            table.insert(out, line)
          end
        end
      end
      return out
    end

    local function strip_comments(lines, ft)
      ft = ft or vim.bo.filetype
      local markers = comment_markers[ft]
      if not markers then
        return lines
      end

      local out_lines = lines

      if #markers >= 3 then
        out_lines = strip_block_comments(out_lines, markers[2], markers[3])
      end

      local single = markers[1]
      if single then
        local pat_full = '^%s*' .. escape_for_pattern(single) .. '%s*'
        local inline_pat = '%s+' .. escape_for_pattern(single) .. '.*$'
        local out = {}
        for _, line in ipairs(out_lines) do
          if not line:match(pat_full) then
            local cleaned = line:gsub(inline_pat, '')
            cleaned = cleaned:gsub('%s+$', '')
            if cleaned:match '%S' then
              table.insert(out, cleaned)
            end
          end
        end
        return out
      end

      return out_lines
    end

    -- Send a range (0-based inclusive) from a buffer to the REPL, using treesitter when possible.
    local function send_filtered_range(bufnr, from, to)
      bufnr = bufnr or 0
      local buffer_length = vim.api.nvim_buf_line_count(bufnr)
      from = from or 0
      to = to or (buffer_length - 1)
      if from < 0 then
        from = 0
      end
      if to >= buffer_length then
        to = buffer_length - 1
      end

      local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
      local filtered = nil

      if has_ts_filter then
        local ok, res = pcall(ts_filter.strip_comments, bufnr, from, to)
        if ok and res and #res > 0 then
          filtered = res
        end
      end

      if not filtered then
        local lines = vim.api.nvim_buf_get_lines(bufnr, from, to + 1, false)
        filtered = strip_comments(lines, ft)
      end

      if not filtered or #filtered == 0 then
        return
      end
      iron.send(ft, filtered)
    end

    -- Keep a small compatibility wrapper for callers that previously provided data directly.
    local function send_filtered(ft, data)
      if type(data) == 'string' then
        -- send a single line string; use current buffer/line
        local linenr = vim.api.nvim_win_get_cursor(0)[1] - 1
        send_filtered_range(0, linenr, linenr)
      elseif type(data) == 'table' then
        -- data is a table of lines; send as-is using fallback cleaning
        local ft = ft or vim.bo.filetype
        local filtered = strip_comments(data, ft)
        if not filtered or #filtered == 0 then
          return
        end
        iron.send(ft, filtered)
      end
    end

    -- Wrapper functions for common send actions
    local function send_line_filtered()
      local linenr = vim.api.nvim_win_get_cursor(0)[1] - 1
      local cur_line = vim.api.nvim_buf_get_lines(0, linenr, linenr + 1, false)[1]
      if not cur_line or cur_line:match '^%s*$' then
        return
      end
      send_filtered_range(0, linenr, linenr)
    end

    local function visual_send_filtered()
      -- Use visual marks to determine the selected lines and send whole lines.
      -- Note: partial-column visual selections will be sent as full lines.
      local s = vim.fn.getpos "'<"
      local e = vim.fn.getpos "'>"
      if not s or not e then
        return
      end
      local from = s[2] - 1
      local to = e[2] - 1
      if from > to then
        local tmp = from
        from = to
        to = tmp
      end
      send_filtered_range(0, from, to)
    end

    local function send_file_filtered()
      local buffer_length = vim.api.nvim_buf_line_count(0)
      if buffer_length == 0 then
        return
      end
      send_filtered_range(0, 0, buffer_length - 1)
    end

    local function send_until_cursor_filtered()
      local linenr = vim.api.nvim_win_get_cursor(0)[1] - 1
      send_filtered_range(0, 0, linenr)
    end

    local function send_mark_filtered()
      local marks_mod = require 'iron.marks'
      local pos = marks_mod.get()
      if not pos then
        return
      end
      -- pos.from_line/pos.to_line are 0-based ranges from iron.marks.get()
      -- We send whole lines for simplicity; partial-column marks will be sent as full lines.
      send_filtered_range(0, pos.from_line, pos.to_line)
    end

    local function send_code_block_filtered(move)
      local ft = vim.bo.filetype
      local repl_def = require('iron.config').repl_definition
      local cfg = repl_def[ft]
      if not cfg or not cfg.block_dividers then
        -- fallback to core behaviour if no dividers
        require('iron.core').send_code_block(move)
        return
      end

      local block_dividers = cfg.block_dividers
      local linenr = vim.api.nvim_win_get_cursor(0)[1] - 1
      local buffer_text = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local mark_start = linenr
      while mark_start ~= 0 do
        local line_text = buffer_text[mark_start + 1]
        local found = false
        for _, bd in ipairs(block_dividers) do
          if line_text:sub(1, #bd) == bd then
            found = true
            break
          end
        end
        if found then
          break
        end
        mark_start = mark_start - 1
      end
      local buffer_length = vim.api.nvim_buf_line_count(0)
      local mark_end = linenr + 1
      while mark_end < buffer_length do
        local line_text = buffer_text[mark_end + 1]
        local found = false
        for _, bd in ipairs(block_dividers) do
          if line_text:sub(1, #bd) == bd then
            found = true
            break
          end
        end
        if found then
          break
        end
        mark_end = mark_end + 1
      end
      mark_end = mark_end - 1
      local col_end = string.len(buffer_text[mark_end + 1]) - 1

      send_filtered_range(0, mark_start, mark_end)

      if move then
        vim.api.nvim_win_set_cursor(0, { math.min(mark_end + 2, buffer_length), 0 })
      end
    end

    -- Override the iron keymaps that send to the REPL with filtered variants
    -- (This replaces the earlier iron.setup keymaps which map directly to iron.core.send)
    vim.keymap.set('n', '<leader>rl', send_line_filtered, { desc = 'REPL: [R]un [L]ine (no comments)' })
    vim.keymap.set('v', '<leader>rv', function()
      visual_send_filtered()
    end, { desc = 'REPL: [R]epl [V]isual (no comments)' })
    vim.keymap.set('n', '<leader>rf', send_file_filtered, { desc = 'REPL: [R]un [F]ile (no comments)' })
    vim.keymap.set('n', '<leader>ru', send_until_cursor_filtered, { desc = 'REPL: [R]un [U]ntil (no comments)' })
    vim.keymap.set('n', '<leader>rm', send_mark_filtered, { desc = 'REPL: [R]un [M]ark (no comments)' })
    vim.keymap.set('n', '<leader>rb', function()
      send_code_block_filtered(false)
    end, { desc = 'REPL: [R]un [B]lock (no comments)' })
    vim.keymap.set('n', '<leader>rn', function()
      send_code_block_filtered(true)
    end, { desc = 'REPL: [R]un [N]ext (no comments then move)' })

    -- Helpful commands to focus/hide the REPL (no conflict with send keys above)
    vim.keymap.set('n', '<leader>rF', '<cmd>IronFocus<cr>', { desc = 'REPL: [R]epl [F]ocus - Focus the REPL window' })
    vim.keymap.set('n', '<leader>rH', '<cmd>IronHide<cr>', { desc = 'REPL: [R]epl [H]ide - Hide the REPL window' })
  end,
}
