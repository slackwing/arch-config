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
  end,
}
