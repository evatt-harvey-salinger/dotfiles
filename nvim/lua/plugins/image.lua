return {
  {
    "3rd/image.nvim",
    event = "VeryLazy", -- Load when needed, e.g., when opening a markdown file
    dependencies = {
      -- nvim-treesitter is managed by NvChad, but image.nvim needs its parsers
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      backend = "kitty",
      -- processor = "magick_cli", -- Uses ImageMagick CLI tools
      processor = "magick_rock", -- Uses ImageMagick CLI tools
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          -- Add "codecompanion" if you want image.nvim to work in its buffers
          filetypes = { "markdown", "vimwiki", "codecompanion" },
        },
        neorg = { -- If you use Neorg
          enabled = true,
          filetypes = { "norg" },
        },
        typst = { -- If you use Typst
            enabled = false, -- Set to true if you use typst
            filetypes = { "typst" },
        },
        html = {
            enabled = false, -- Set to true if you want HTML image previews
        },
        css = {
            enabled = false, -- Set to true if you want CSS image previews
        },
        -- Add other integrations as needed
      },
      max_width_window_percentage = 70, -- Example: images won't exceed 70% of window width
      max_height_window_percentage = 50, -- Example: images won't exceed 50% of window height
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- Opens these files directly as images
      -- Optional: If you want to use the magick_rock processor later,
      -- you would change 'processor' and ensure LuaRocks setup.
      -- For magick_cli, explicitly setting build = false can prevent issues if hererocks is globally enabled.
      -- build = false, -- Uncomment if you have `hererocks = true` in your main lazy config and want to ensure CLI for this.
    },
  },

  -- Ensure nvim-treesitter is configured to install necessary parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts) -- Extend NvChad's default Treesitter options
      local ensure_installed_extended = {
        "markdown", -- For markdown integration
        "norg",     -- For neorg integration (if enabled)
        "html",     -- For html integration (if enabled)
        "css",      -- For css integration (if enabled)
        "typst",    -- For typst integration (if enabled)
      }
      -- Add to existing NvChad ensure_installed, avoiding duplicates
      for _, parser in ipairs(ensure_installed_extended) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
      return opts
    end,
  },
  -- test new blin
  -- { import = "nvchad.blink.lazyspec" },
}
