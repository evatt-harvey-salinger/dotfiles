return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
  keys = {
    {
      '<leader>dv',
      function()
        local diffview = require 'diffview.lib'
        local view = diffview.get_current_view()
        if view then
          vim.cmd 'DiffviewClose'
        else
          vim.cmd 'DiffviewOpen'
        end
      end,
      desc = 'Toggle Diffview',
    },
    { '<leader>dc', '<cmd>DiffviewClose<cr>', desc = 'Close Diffview' },
    { '<leader>df', '<cmd>DiffviewFileHistory<cr>', desc = 'Diffview File History' },
  },
  config = function()
    require('diffview').setup()
  end,
}
