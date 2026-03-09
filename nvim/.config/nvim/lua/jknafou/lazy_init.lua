local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = "jknafou.lazy",
    change_detection = { notify = false }
})

vim.schedule(function()
  vim.opt.rtp:remove("/opt/homebrew/Cellar/neovim/0.10.4_1/lib/nvim")
end)
