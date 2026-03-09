return {
    "nvim-neotest/neotest",
    dependencies = {
		"nvim-neotest/neotest-python",
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "fredrikaverpil/neotest-golang",
        "leoluz/nvim-dap-go",
    },
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-python")({
					-- Extra arguments for nvim-dap configuration
					-- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
					dap = { justMyCode = false },
					-- Command line arguments for runner
					-- Can also be a function to return dynamic values
					args = {"--log-level", "DEBUG"},
					-- Runner to use. Will use pytest if available by default.
					-- Can be a function to return dynamic value.
					runner = "pytest",
					-- Custom python path for the runner.
					-- Can be a string or a list of strings.
					-- Can also be a function to return dynamic value.
					-- If not provided, the path will be inferred by checking for
					-- virtual envs in the local directory and for Pipenev/Poetry configs
					python = ".venv/bin/python",
					-- Returns if a given file path is a test file.
					-- NB: This function is called a lot so don't perform any heavy tasks within it.
					-- is_test_file = function(file_path)
					-- 	...
					-- end,
					-- !!EXPERIMENTAL!! Enable shelling out to `pytest` to discover test
					-- instances for files containing a parametrize mark (default: false)
					pytest_discover_instances = true,
				})
			}
		})

		vim.keymap.set("n", "<leader>tr", "<cmd>Neotest run<CR>", { desc = "Test: Run Nearest Test" })
		vim.keymap.set("n", "<leader>ti", "<cmd>Neotest output<CR>", { desc = "Test: Output" })
		vim.keymap.set("n", "<leader>ts", "<cmd>Neotest summary<CR>", { desc = "Test: Summary" })
		vim.keymap.set("n", "<leader>ta", "<cmd>lua require('neotest').run.run({suite = true})<CR>", { desc = "Test: Run All Tests" })

        -- vim.keymap.set("n", "<leader>tr", function()
        --     require("neotest").run.run({
        --         suite = false,
        --         testify = true,
        --     })
        -- end, { desc = "Debug: Running Nearest Test" })
        --
        -- vim.keymap.set("n", "<leader>tv", function()
        --     require("neotest").summary.toggle()
        -- end, { desc = "Debug: Summary Toggle" })
        --
        -- vim.keymap.set("n", "<leader>ts", function()
        --     require("neotest").run.run({
        --         suite = true,
        --         testify = true,
        --     })
        -- end, { desc = "Debug: Running Test Suite" })
        --
        -- vim.keymap.set("n", "<leader>td", function()
        --     require("neotest").run.run({
        --         suite = false,
        --         testify = true,
        --         strategy = "dap",
        --     })
        -- end, { desc = "Debug: Debug Nearest Test" })
        --
        -- vim.keymap.set("n", "<leader>to", function()
        --     require("neotest").output.open()
        -- end, { desc = "Debug: Open test output" })
        --
        -- vim.keymap.set("n", "<leader>ta", function()
        --     require("neotest").run.run(vim.fn.getcwd())
        -- end, { desc = "Debug: Open test output" })

    end
}
