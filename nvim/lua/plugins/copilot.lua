return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      filetypes = {
        yaml = true,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = '<M-y>',
          next = nil,
          prev = nil,
          dismiss = nil,
        },
      },
      panel = { enabled = false },
    }
  end,
}
