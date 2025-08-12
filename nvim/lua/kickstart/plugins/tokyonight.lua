return {
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false }, -- Disable italics in comments
        },
        -- -- NOT WORKING
        -- on_highlights = function(highlights, colors)
        --   highlights.VertSplit = {
        --     -- fg = colors.fg_dark,
        --     fg = colors.fg_gutter,
        --     bg = colors.none,
        --   }
        --   highlights.WinSeparator = {
        --     fg = colors.border,
        --     bg = colors.none,
        --   }
        -- end,
      }

      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-moon'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
