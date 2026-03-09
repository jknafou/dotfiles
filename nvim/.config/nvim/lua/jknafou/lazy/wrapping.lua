return {
  "andrewferrier/wrapping.nvim",
  lazy = false,
  config = function()
    require("wrapping").setup({
      auto_set_mode_filetype_allowlist = { "markdown", "text", "latex", "asciidoc", "rst", "gitcommit", "mail", "tex" },
    })
  end,
}
