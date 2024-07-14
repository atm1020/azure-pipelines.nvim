local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

local M = {}

local function calc_size(lines)
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end

	return {
		width = math.min(width, math.floor(vim.o.columns * 0.8)),
		height = math.min(#lines, math.floor(vim.o.lines * 0.8)),
	}
end

function M.show_popup(top_text, botton_text, size, callback)
	local popup = Popup({
		enter = true,
		focusable = true,
		size = {
			width = size.width or 80,
			height = size.height or 20,
		},
		border = {
			style = 'rounded',
			text = {
				top = top_text,
				top_align = 'center',
				bottom = botton_text,
				bottom_align = 'left',
			},
		},
		position = '50%',
		win_options = {
			winhighlight = 'Normal:Normal,FloatBorder:Normal',
		},
	})

	callback(popup.bufnr)
	popup:mount()
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)
	return popup.bufnr
end

function M.pipeline_preview_popup(yaml_content, pipeline_name)
	M.show_popup(
		'Pipeline Preview',
		pipeline_name,
		calc_size(yaml_content),
		function(popup_bufnr)
			vim.api.nvim_set_option_value('buftype', 'nofile', { buf = popup_bufnr })
			vim.api.nvim_set_option_value('filetype', 'yaml', { buf = popup_bufnr })
			vim.api.nvim_buf_set_lines(popup_bufnr, 0, -1, false, yaml_content)
		end
	)
end

function M.error_msg_popup(err_msg)
	M.show_popup(
		'Pipeline Preview Error',
		'error message',
		calc_size({ err_msg }),
		function(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { err_msg })
			vim.api.nvim_command('highlight RedText ctermfg=LightRed guifg=#FF6666')
			vim.api.nvim_buf_add_highlight(bufnr, -1, 'RedText', 0, 0, -1)
		end
	)
end

--- @param items string[]
--- @param on_select fun(item: string)
--- @param on_close fun()|nil
--- @param title string
--- @param separator string|nil
function M.select_list(items, title, on_select, separator, on_close)
	local Menu = require('nui.menu')
	local menu_items = {}
	if separator then
		table.insert(menu_items, Menu.separator(separator))
	end
	for _, item in ipairs(items) do
		table.insert(menu_items, Menu.item(item))
	end

	local menu = Menu({
		position = '50%',
		size = {
			width = 40,
			height = 10,
		},
		border = {
			style = 'single',
			text = {
				top = '[' .. title .. ']',
				top_align = 'center',
			},
		},
		win_options = {
			winhighlight = 'Normal:Normal,FloatBorder:Normal',
		},
	}, {
		lines = menu_items,
		max_width = 20,
		keymap = {
			focus_next = { 'j', '<Down>', '<Tab>' },
			focus_prev = { 'k', '<Up>', '<S-Tab>' },
			close = { '<Esc>', '<C-c>' },
			submit = { '<CR>', '<Space>' },
		},
		on_close = function()
			if on_close then
				on_close()
			end
		end,
		on_submit = function(item)
			on_select(item.text)
		end,
	})

	menu:on(event.BufLeave, function()
		menu:unmount()
	end)

	menu:mount()
end

return M
