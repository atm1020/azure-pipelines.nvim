local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

local M = {}

--- @param str string
--- @return boolean
function M.is_contains_postfix(str, postfix)
	return str:match('^(.*)' .. postfix)
end

--- @param name string
--- @return boolean
function M.is_contains_active_postfix(name)
	return M.is_contains_postfix(name, '(active)')
end

--- @param name string
--- @return string
function M.clear_postfix(name)
	local val, _ = name:gsub(' %(.+%)', '')
	return val
end

function M.set_popup_value(bufnr, value)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { value })
end

function M.calc_size(lines)
	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, #line)
	end

	return {
		width = math.min(width, math.floor(vim.o.columns * 0.8)),
		height = math.min(#lines, math.floor(vim.o.lines * 0.8)),
	}
end

--- @param up_win number
--- @param down_win number
function M.map_keys_for_profile_editor(popup, up_win, down_win)
	local function go_up()
		vim.api.nvim_set_current_win(up_win)
	end

	local function go_down()
		vim.api.nvim_set_current_win(down_win)
	end

	popup:map('n', '<Tab>', go_down)
	popup:map('n', 'k', go_up)
	popup:map('n', 'j', go_down)
end

function M.get_popup_value(popup)
	local ok, value = pcall(vim.api.nvim_buf_get_lines, popup.bufnr, 0, -1, false)
	if ok then
		return value[1]
	end
end

function M.get_and_fill_popup(title, enter, keymaps)
	local win_options = {
		winhighlight = 'Normal:Normal,FloatBorder:Normal',
	}
	local style = 'single'

	local text = {
		top = '[' .. title .. ']',
		top_align = 'center',
	}

	if keymaps then
		text.bottom = '[s]ave [b]ack [q]uit'
		text.bottom_align = 'center'
	end

	local popup = Popup({
		border = {
			style = style,
			text = text,
		},
		enter = enter or false,
		win_options = win_options,
	})

	return popup
end

function M.base_list(items, title, on_select, separator, on_close, bottom_text)
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
		relative = 'editor',
		size = {
			width = 40,
			height = 10,
		},
		border = {
			style = 'single',
			text = {
				top = '[' .. title .. ']',
				top_align = 'center',
				bottom = bottom_text or '',
				-- bottom = "BOTTOM"
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
	return menu
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
		relative = 'editor',
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

return M
