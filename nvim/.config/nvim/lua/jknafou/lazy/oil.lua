return {
	{
		'stevearc/oil.nvim',
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {

			-- See :help oil-config for a complete list of options
			-- See :help oil.setup()
			-- See :help oil-filetype
			view_options = {
				-- Show files and directories that start with "."
				show_hidden = true,
				-- Show files and directories that start with "."
				show_dotfiles = true,
				-- Show files and directories that start with "_"
				show_ignored = false,
			},
		},
		-- Optional dependencies
		dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
	}
}
