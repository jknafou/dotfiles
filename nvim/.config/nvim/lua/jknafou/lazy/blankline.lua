return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "VeryLazy",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    indent = {
      char = "│",
      tab_char = "│",
    },
    whitespace = {
      remove_blankline_trail = false, -- Show indent on blank lines
    },
    scope = {
      show_start = false,
      show_end = false,
    },
    exclude = {
      filetypes = { "help", "dashboard", "neo-tree", "lazy", "mason" },
    },
  },
}

