return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#0b0f1a',
				base01 = '#0b0f1a',
				base02 = '#998ca5',
				base03 = '#998ca5',
				base04 = '#f0e0ff',
				base05 = '#f8f2ff',
				base06 = '#f8f2ff',
				base07 = '#f8f2ff',
				base08 = '#ff3f61',
				base09 = '#ff3f61',
				base0A = '#9926ff',
				base0B = '#4cff76',
				base0C = '#c98cff',
				base0D = '#9926ff',
				base0E = '#ab4cff',
				base0F = '#ab4cff',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#998ca5',
				fg = '#f8f2ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#9926ff',
				fg = '#0b0f1a',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#998ca5' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#c98cff', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#ab4cff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#9926ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#9926ff',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#c98cff',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#4cff76',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#f0e0ff' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#f0e0ff' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#998ca5',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
