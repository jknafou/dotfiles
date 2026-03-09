vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = false  -- Default to tabs globally
vim.opt.smartindent = true -- Keep globally

vim.opt.wrap = true
vim.opt.linebreak = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

-- Function to set scrolloff to half the window height
local function set_dynamic_scrolloff()
  local win_height = vim.api.nvim_win_get_height(0)
  vim.opt.scrolloff = math.floor(win_height / 3)
end

-- Set initially
set_dynamic_scrolloff()

-- vim.opt.scrolloff = 30
-- Update on VimResized event
vim.api.nvim_create_autocmd("VimResized", {
  callback = set_dynamic_scrolloff,
})

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"
