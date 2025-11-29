return {
  "navarasu/onedark.nvim",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('onedark').setup {
      style = 'warmer',
      transparent = true,  -- Let onedark handle transparency for most elements
      code_style = {
        comments = 'italic',
        keywords = 'bold',
        functions = 'bold',
        strings = 'none',
        variables = 'none'
      }
    }
    -- Step 2: Apply onedark colors (init.lua will override Normal/NormalNC after)
    require('onedark').load()
  end
}
