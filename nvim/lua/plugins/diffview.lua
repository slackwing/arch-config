return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'lewis6991/gitsigns.nvim' },
  config = function()
    require('diffview').setup {
      -- TODO
    }
    local function get_default_branch_name()
      local res = vim.system({ 'git', 'rev-parse', '--verify', 'main' }, { capture_output = true }):wait()
      return res.code == 0 and 'main' or 'master'
    end
    -- Historical diff of line (like blame).
    vim.keymap.set('n', ',,l', '<Cmd>.DiffviewFileHistory --follow<CR>', { desc = 'Line history' })
    -- Historical diff of visual selection (like blame).
    vim.keymap.set('v', ',,v', "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>", { desc = 'Visual selection history' })
    -- Diff of open files (git).
    vim.keymap.set('n', ',,d', '<cmd>DiffviewOpen<cr>', { desc = 'Open files diff' })
    -- Diff against (local) master branch.
    vim.keymap.set('n', ',,m', function()
      vim.cmd('DiffviewOpen ' .. get_default_branch_name())
    end, { desc = 'Diff against master' })
    -- Historical diff of current file.
    vim.keymap.set('n', ',,f', '<cmd>DiffviewFileHistory --follow %<cr>', { desc = 'File history' })
    -- History of repo.
    vim.keymap.set('n', ',,r', '<cmd>DiffviewFileHistory<cr>', { desc = 'Repo history' })
    -- Close tab.
    vim.keymap.set('n', ',,q', ':tabc<CR>', { silent = true })
  end,
}
