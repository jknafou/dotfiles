return {
	{
		-- https://github.com/nvim-treesitter/nvim-treesitter
		'nvim-treesitter/nvim-treesitter',
		event = 'VeryLazy',
		dependencies = {
			-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
			'nvim-treesitter/nvim-treesitter-textobjects',
		},
		build = ':TSUpdate',
		opts = {
			highlight = {
				enable = true,
			},
			indent = { enable = true },
			auto_install = true, -- automatically install syntax support when entering new file type buffer
			ensure_installed = {
				'lua',
			},
		},
		config = function (_, opts)
			local configs = require("nvim-treesitter.configs")
			configs.setup(opts)
		end
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },  -- Better than "after" for lazy.nvim
		config = function()
			require("treesitter-context").setup({
				enable = true,
				mode = "cursor",  -- 'topline' or 'cursor'
				max_lines = 3,    -- Show up to 3 context lines
				multiline_threshold = 5,  -- Min lines for multi-line context
				separator = "─",  -- Visual separator line
				zindex = 20,
				on_attach = function(bufnr)
					-- Optional: Add keymaps for context navigation
					vim.keymap.set("n", "[c", function() require("treesitter-context").go_to_context() end, { buffer = bufnr })
				end
			})
		end
	}
}

