return {
  {
    "neovim/nvim-lspconfig",
    ft = "python",
    opts = function()
      -- Override global settings for Python
      vim.opt_local.expandtab = true   -- Use spaces instead of tabs
      vim.opt_local.tabstop = 4        -- 4 spaces per tab
      vim.opt_local.shiftwidth = 4     -- 4 spaces per indent
      vim.opt_local.softtabstop = 4    -- 4 spaces per <Tab> keypress
      vim.opt_local.smartindent = false -- Disable to prevent conflicts
    end,
  },
}

