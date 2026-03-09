return {
	  "vim-test/vim-test",
	  dependencies = {
		  "preservim/vimux",
	  },
	  vim.keymap.set("n", "<leader>tt", "<cmd>TestNearest<cr>", { desc = "Run nearest test" }),
	  vim.keymap.set("n", "<leader>tf", "<cmd>TestFile<cr>", { desc = "Run tests in file" }),
	  vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<cr>", { desc = "Run last test" }),
	  vim.keymap.set("n", "<leader>ts", "<cmd>TestSuite<cr>", { desc = "Run test suite" }),
	  vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<cr>", { desc = "Visit last test result" }),
	  vim.cmd("let test#strategy = 'vimux'"),
}
