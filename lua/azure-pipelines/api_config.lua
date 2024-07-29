local Layout = require('nui.layout')
local ui = require('azure-pipelines.utils.ui')
local config = require('azure-pipelines.config_handler')
local event = require('nui.utils.autocmd').event
local api = require('azure-pipelines.azure_devops_api')
local async = require('plenary.async')

local M = {}

local function get_config_popup()
	return {
		name = ui.get_and_fill_popup('Unique config name', true, false),
		org_name = ui.get_and_fill_popup('Organization name', false, false),
		project_name = ui.get_and_fill_popup('Project name', false, false),
		api_token = ui.get_and_fill_popup('B64 encoded token', false, true),
	}
end

local function save_profile(popups)
	local key = ui.get_popup_value(popups.name)
	local org_name = ui.get_popup_value(popups.org_name)
	local project_name = ui.get_popup_value(popups.project_name)
	local api_token = ui.get_popup_value(popups.api_token)

	assert(key and key ~= '', 'config name is required')
	assert(org_name and org_name ~= '', 'org_name is required')
	assert(project_name and project_name ~= '', 'project_name is required')
	assert(api_token and api_token ~= '', 'api_token is required')

	if not key or not org_name or not project_name or not api_token then
		vim.notify('All fields are required', vim.log.levels.ERROR, {})
		return false
	end

	--- @type AzDevopsApiConfig
	local profile = {
		org_name = org_name,
		project_name = project_name,
		api_token = api_token,
	}

	local ok = config.save_api_config_value(key, profile)
	if ok then
		return true
	end
	return false
end

local function open_api_config_editor(popups)
	local layout = Layout(
		{
			relative = 'editor',
			position = '50%',
			size = { height = 15, width = 60 },
		},

		Layout.Box({
			Layout.Box(popups.name, { grow = 0.4 }),
			Layout.Box(popups.org_name, { grow = 0.4 }),
			Layout.Box(popups.project_name, { grow = 0.4 }),
			Layout.Box(popups.api_token, { grow = 0.5 }),
		}, { dir = 'col' })
	)
	layout:mount()

	for _, popup in pairs(popups) do
		-- go back
		popup:map('n', 'b', function()
			layout:unmount()
			M.select_api_config()
		end)
		popup:map('n', 'q', function()
			layout:unmount()
		end)
		-- save
		popup:map('n', 's', function()
			if save_profile(popups) then
				layout:unmount()
			end
		end)
	end
	ui.map_keys_for_profile_editor(
		popups.name, -- popup (first)
		popups.api_token.winid, -- up_win
		popups.org_name.winid -- down_win
	)

	ui.map_keys_for_profile_editor(
		popups.org_name, -- popup (second)
		popups.name.winid, -- up_win
		popups.project_name.winid -- down_win
	)
	ui.map_keys_for_profile_editor(
		popups.project_name, -- popup (third)
		popups.org_name.winid, -- up_win
		popups.api_token.winid -- down_win
	)
	ui.map_keys_for_profile_editor(
		popups.api_token, -- popup (fourth)
		popups.project_name.winid, -- up_win
		popups.name.winid -- down_win
	)
end

local function select_api_config()
	local api_config = config.get_api_config_list()
	if not api_config then
		open_api_config_editor(get_config_popup())
		return
	end

	local items = {}
	for key, _ in pairs(api_config) do
		if key == config.get_default_api_config_key() then
			key = key .. ' (active)'
		end
		table.insert(items, key)
	end

	local on_select = function(selected_key)
		if ui.is_contains_active_postfix(selected_key) then
			selected_key = ui.clear_postfix(selected_key)
		end

		local profile = config.get_api_config_by_key(selected_key)
		local popup = get_config_popup()
		ui.set_popup_value(popup.name.bufnr, selected_key)
		ui.set_popup_value(popup.org_name.bufnr, profile.org_name)
		ui.set_popup_value(popup.project_name.bufnr, profile.project_name)
		open_api_config_editor(popup)
	end
	local menu = ui.base_list(
		items,
		'API Configs (global)',
		on_select,
		nil,
		function() end,
		'[a]ctive [d]delete [n]ew [q]uit'
	)

	local focus_item = nil
	menu:on(event.CursorMoved, function()
		focus_item = menu.tree:get_node()
	end)

	menu:map('n', 'a', function()
		local selected_key = focus_item.text
		config.set_api_config_for_current_project(selected_key)
		api.refresh_config()
		menu:unmount()
	end)

	menu:map('n', 'n', function()
		menu:unmount()
		open_api_config_editor(get_config_popup())
	end)

	menu:map('n', 'q', function()
		menu:unmount()
	end)

	menu:map('n', 'd', function()
		local selected_key = focus_item.text
		if ui.is_contains_active_postfix(selected_key) then
			error('Cannot delete active profile')
		end
		config.delete_api_config_by_key(selected_key)
		menu:unmount()
		M.select_api_config()
	end)

	menu:mount()
end

function M.select_api_config()
	async.run(select_api_config)
end

return M
