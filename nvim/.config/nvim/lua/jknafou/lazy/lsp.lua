return {
	"neovim/nvim-lspconfig",
	dependencies = {
		{
			"folke/lazydev.nvim",
			ft = "lua", -- only load on lua files
			opts = {
				library = {
					-- See the configuration section for more details
					-- Load luvit types when the `vim.uv` word is found
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
		"stevearc/conform.nvim",
		{ "mason-org/mason.nvim", version = "^1.0.0" },
		{ "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
		-- "williamboman/mason.nvim",
		-- "williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
	},

    config = function()
        require("conform").setup({
            formatters_by_ft = {
            }
        })
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            automatic_installation = true,  -- or false if you prefer manual installs

            ensure_installed = {
                "lua_ls",
                "rust_analyzer",
                "gopls",
                "ruff",
                "pyright",
                "pylsp",
				"texlab",
            },
            handlers = {
                function(server_name) -- default handler (optional)
                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                zls = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.zls.setup({
                        root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
                        settings = {
                            zls = {
                                enable_inlay_hints = true,
                                enable_snippets = true,
                                warn_style = true,
                            },
                        },
                    })
                    vim.g.zig_fmt_parse_errors = 0
                    vim.g.zig_fmt_autosave = 0
                end,
                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                format = {
                                    enable = true,
                                    -- Put format options here
                                    -- NOTE: the value should be STRING!!
                                    defaultConfig = {
                                        indent_style = "space",
                                        indent_size = "2",
                                    }
                                },
                            }
                        }
                    }
                end,
                ["pyright"] = function()
                    local lspconfig = require("lspconfig")
                    local util = lspconfig.util
                    lspconfig.pyright.setup({
                        root_dir = function(fname)
                            -- First find the Rye project root
                            local rye_root = util.root_pattern(
                                ".git",
                                "pyproject.toml",
                                "setup.py",
                                "setup.cfg",
                                "requirements.txt"
                            )(fname)

                            -- If Rye root found, check for src directory
                            if rye_root then
                                local src_dir = util.path.join(rye_root, "src")
                                -- Use src directory if it exists, otherwise use Rye root
                                return util.path.is_dir(src_dir) and src_dir or rye_root
                            end

                            -- Fallback for non-Rye projects
                            return util.root_pattern(".git", "setup.py", "requirements.txt")(fname)
                        end,
                        settings = {
                            python = {
                                analysis = {
                                    typeCheckingMode = "basic",
                                    autoImportCompletions = true,
                                    useLibraryCodeForTypes = true,
                                    diagnosticMode = "workspace",
                                    diagnosticSeverityOverrides = {
                                        reportMissingImports = "none",
                                        reportMissingTypeStubs = "none",
                                        reportUnusedImport = "none",
                                        reportUnusedClass = "none",
                                        reportUnusedFunction = "none",
                                        reportUnusedVariable = "none",
                                    },
                                },
                            },
                        },
                    })
                end,
                ["pylsp"] = function()
                    local lspconfig = require("lspconfig")
                    local util = lspconfig.util
                    lspconfig.pylsp.setup({
                        root_dir = function(fname)
                            -- First find the Rye project root
                            local rye_root = util.root_pattern(
                                ".git",
                                "pyproject.toml",
                                "setup.py",
                                "setup.cfg",
                                "requirements.txt"
                            )(fname)

                            -- If Rye root found, check for src directory
                            if rye_root then
                                local src_dir = util.path.join(rye_root, "src")
                                -- Use src directory if it exists, otherwise use Rye root
                                return util.path.is_dir(src_dir) and src_dir or rye_root
                            end

                            -- Fallback for non-Rye projects
                            return util.root_pattern(".git", "setup.py", "requirements.txt")(fname)
                        end,
                        settings = {
                            pylsp = {
                                plugins = {
                                    pycodestyle = { enabled = false }, -- Disable pycodestyle
                                    rope_autoimport = {
                                        enabled = true,                -- Enable autoimport
                                        completions = { enabled = true },   -- Enable autoimport completions (optional)
                                        code_actions = { enabled = true },  -- Enable autoimport code actions (optional)
                                    },
                                    rope_completion = { enabled = true }, -- Enable Rope-based completions (optional)
                                    -- You can also enable isort for better import sorting:
                                    isort = { enabled = true },
                                },
                            },
                        },
                    })
                end,
                ["ruff"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.ruff.setup({
                        -- Add any custom settings here if needed
                    })

                    -- Format on save for buffers attached to Ruff
                    vim.api.nvim_create_autocmd("LspAttach", {
                        callback = function(args)
                            local client = vim.lsp.get_client_by_id(args.data.client_id)
                            if client and client.name == "ruff" then
                                vim.api.nvim_create_autocmd("BufWritePre", {
                                    buffer = args.buf,
                                    callback = function()
                                        vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
                                    end,
                                })
                            end
                        end,
                    })
				end,
				["texlab"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.texlab.setup({
						capabilities = capabilities, -- Use the same capabilities as other LSPs
						settings = {
							texlab = {
								build = {
									executable = "tectonic",
									args = { "%f", "--synctex" },
									forwardSearchAfter = true,
								},
								forwardSearch = {
									executable = "zathura",
									args = { "--synctex-forward", "%l:1:%f", "%p" },
								},
								chktex = {
									onOpenAndSave = true,
								},
							},
						},
					})
				end,
			}
		})

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = "copilot", group_index = 2 },
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        vim.diagnostic.config({
            -- update_in_insert = true,
            float = {
                focusable = true,
                style = "minimal",
                border = "rounded",
                source = true,
                header = "",
                prefix = "",
            },
        })
    end
}
