return {
	"roxma/vim-tmux-clipboard",
	config = function()
		-- Enable tmux clipboard integration
		vim.g.clipboard = {
			name = "tmux",
			copy = {
				["+"] = {"tmux", "load-buffer", "-"},
				["*"] = {"tmux", "load-buffer", "-"},
			},
			paste = {
				["+"] = {"tmux", "save-buffer", "-"},
				["*"] = {"tmux", "save-buffer", "-"},
			},
			cache_enabled = 1,
		}

		-- Enhanced keymaps for tmux clipboard integration
		-- Copy to tmux buffer and system clipboard
		vim.keymap.set({"n", "v"}, "<leader>ty", function()
			-- First copy to system clipboard (existing behavior)
			vim.cmd('normal! "+y')
			-- Then copy to tmux buffer
			vim.fn.system("tmux load-buffer -", vim.fn.getreg("+"))
			print("Copied to tmux buffer and system clipboard")
		end, { desc = "Copy to tmux buffer and system clipboard" })

		-- Paste from tmux buffer
		vim.keymap.set({"n", "v"}, "<leader>tp", function()
			local tmux_buffer = vim.fn.system("tmux save-buffer -")
			-- Remove trailing newline if present
			tmux_buffer = tmux_buffer:gsub("\n$", "")
			vim.fn.setreg("+", tmux_buffer)
			vim.cmd('normal! "+p')
			print("Pasted from tmux buffer")
		end, { desc = "Paste from tmux buffer" })

		-- Show tmux buffer content
		vim.keymap.set("n", "<leader>tb", function()
			local tmux_buffer = vim.fn.system("tmux save-buffer -")
			if tmux_buffer and tmux_buffer ~= "" then
				print("Tmux buffer: " .. tmux_buffer:gsub("\n", "\\n"))
			else
				print("Tmux buffer is empty")
			end
		end, { desc = "Show tmux buffer content" })
	end
}