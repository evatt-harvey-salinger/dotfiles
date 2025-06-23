-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    config = function()
      vim.g.mkdp_port = '9999' -- or a specific port like 8080
      vim.g.mkdp_echo_preview_url = 1 -- or a specific port like 8080
      vim.g.mkdp_auto_start = 1
    end,
  },
  {
    'szymonwilczek/vim-be-better',
    config = function()
      -- Optional: Enable logging for debugging
      vim.g.vim_be_better_log_file = 1
    end,
  },
}
