require("jknafou.set")
require("jknafou.remap")
require("jknafou.lazy_init")

-- DO.not
-- DO NOT INCLUDE THIS

-- If i want to keep doing lsp debugging
-- function restart_htmx_lsp()
--     require("lsp-debug-tools").restart({ expected = {}, name = "htmx-lsp", cmd = { "htmx-lsp", "--level", "DEBUG" }, root_dir = vim.loop.cwd(), });
-- end

-- DO NOT INCLUDE THIS
-- DO.not

local augroup = vim.api.nvim_create_augroup
local jKnafouGroup = augroup('jKnafou', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require("plenary.reload").reload_module(name)
end

vim.filetype.add({
    extension = {
        templ = 'templ',
    }
})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = jKnafouGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})


autocmd('LspAttach', {
    group = jKnafouGroup,
    callback = function(e)
        local opts = { buffer = e.buf }
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "<leader>K", function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
        vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    end
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.o.exrc = true
vim.o.secure = true

vim.keymap.set("n", "<leader>-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
	callback = function()
		vim.opt.number = false
		vim.opt.relativenumber = false
	end,
})
vim.keymap.set("n", "<leader>st", function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.cmd.startinsert()
	vim.api.nvim_win_set_height(0, 10)
end, { desc = "Split terminal" })

-- Auto-compile LaTeX presentations on save
autocmd("BufWritePost", {
	group = jKnafouGroup,
	pattern = "*/presentation/*.tex",
	callback = function()
		local file = vim.fn.expand("%:p")
		local dir = vim.fn.expand("%:p:h")
		vim.fn.jobstart(
			string.format("cd '%s' && latexmk -pdf -shell-escape -interaction=nonstopmode '%s'", dir, file),
			{
				on_exit = function(_, exit_code)
					if exit_code == 0 then
						print("PDF compiled successfully")
					else
						print("LaTeX compilation failed")
					end
				end
			}
		)
	end,
})

-- Enable soft wrap mode for text-like files
autocmd("FileType", {
	group = jKnafouGroup,
	pattern = { "text", "markdown", "xml", "latex", "tex", "asciidoc", "rst", "gitcommit", "mail" },
	callback = function()
		vim.cmd("SoftWrapMode")
	end,
})
