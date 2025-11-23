return {
  'nvim-mini/mini.diff',
  version = '*',
  config = function()
    require('mini.diff').setup {
      mappings = {
        goto_first = ';h',
        goto_prev = ';k',
        goto_next = ';j',
        goto_last = ';l',
      },
    }
    vim.keymap.set('n', ';a', function()
      vim.cmd 'normal ghgh'
    end, { desc = 'MiniDiff: apply hunk under cursor' })
    vim.keymap.set('n', ';r', function()
      vim.cmd 'normal gHgh'
    end, { desc = 'MiniDiff: reset hunk under cursor' })
    vim.keymap.set('n', ';d', function()
      MiniDiff.toggle_overlay()
    end)
  end,
}
