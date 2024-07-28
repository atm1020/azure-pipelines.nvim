local ui = require('azure-pipelines.utils.ui')
local config = require('azure-pipelines.config_handler')
local api = require('azure-pipelines.azure_devops_api')
local logger = require('azure-pipelines.utils.logger')
local async = require('plenary.async')

local M = {}

--- @enum Mode
local Mode = {
	CurrentBuffer = 'Current Buffer',
	SpecifiedFile = 'Specified File',
	Skip = 'Skip',
}

--- @param name string
--- @return boolean
function M.is_contains_default_postfix(name)
	return M.is_contains_postfix(name, '(default)')
end

--- @param yaml_content string[]
local function pipeline_preview_popup(yaml_content, pipeline_name)
	ui.show_popup(
		'Pipeline Preview',
		pipeline_name,
		ui.calc_size(yaml_content),
		function(popup_bufnr)
			vim.api.nvim_set_option_value('buftype', 'nofile', { buf = popup_bufnr })
			vim.api.nvim_set_option_value('filetype', 'yaml', { buf = popup_bufnr })
			vim.api.nvim_buf_set_lines(popup_bufnr, 0, -1, false, yaml_content)
		end
	)
end

--- @param err_msg string
local function error_msg_popup(err_msg)
	ui.show_popup(
		'Pipeline Preview Error',
		'error message',
		ui.calc_size({ err_msg }),
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
--- @param bottom_text string|nil
local function select_list(
	items,
	title,
	on_select,
	separator,
	on_close,
	bottom_text
)
	local menu =
		ui.base_list(items, title, on_select, separator, on_close, bottom_text)
	menu:mount()
end

local function show_settings()
	local conf = config.get_project_config()

	local data = {}
	table.insert(data, 'Pipeline: ' .. conf.pipeline.name)
	table.insert(data, 'Pipeline ID: ' .. conf.pipeline.id)
	table.insert(data, 'Repository: ' .. conf.repository.name)
	table.insert(data, 'Repository ID: ' .. conf.repository.id)
	table.insert(data, 'Branch: ' .. conf.branch.name)
	table.insert(data, 'Mode: ' .. conf.mode)
	table.insert(data, 'Api Config: ' .. conf.active_api_config_key)

	ui.show_popup(
		'Project Settings',
		nil,
		ui.calc_size(data),
		function(popup_bufnr)
			vim.api.nvim_set_option_value('buftype', 'nofile', { buf = popup_bufnr })
			vim.api.nvim_set_option_value('filetype', 'json', { buf = popup_bufnr })
			vim.api.nvim_buf_set_lines(popup_bufnr, 0, -1, false, data)
		end
	)
end

--- @param preview boolean
local function validate(preview)
	--- @type string|nil
	local content = nil
	if config.get_project_config().pipeline == nil then
		error('Pipeline not selected')
	end
	if config.get_project_config().mode == Mode.CurrentBuffer then
		local bufnr = vim.api.nvim_get_current_buf()
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		content = table.concat(lines, '\n')
	elseif M.mode == Mode.SpecifiedFile then
		vim.notify('Select the file to preview', vim.log.levels.INFO)
		-- TODO
	end
	local resp = api.preview(
		config.get_project_config().pipeline.id,
		config.get_project_config().branch.name,
		content
	)
	if resp.status ~= 200 then
		local err_msg = resp.body.message
		if resp.status ~= 400 then
			err_msg = resp.body
		end
		error_msg_popup(err_msg)
	elseif preview then
		local yaml_lines = vim.split(resp.body.finalYaml, '\n')
		pipeline_preview_popup(
			yaml_lines,
			config.get_project_config().pipeline.name
		)
	else
		vim.notify('Pipeline is valid', vim.log.levels.INFO)
	end
end

--- @param repository_id string
local function select_branch(repository_id)
	local repository = api.get_repository(repository_id)
	local data = api.search_branch(repository_id)
	local branches = {}
	local branch_lookup = {}
	local current_branch = config.get_project_config().branch
	for _, v in pairs(data) do
		local name = v.name
		if current_branch and current_branch.name == v.name then
			name = v.name .. ' (active)'
		end

		if v.name == repository.defaultBranch then
			name = name .. ' (default)'
		end

		table.insert(branches, name)
		branch_lookup[v.name] = v
	end
	local title = 'Select Branch'
	local separator = '[' .. #branches .. ' branches found]'
	local bottom_text = 'repo:' .. repository.name .. ''
	local on_select = function(branch)
		branch = ui.clear_postfix(branch)

		vim.notify('Selected branch: [' .. branch .. ']', vim.log.levels.INFO)
		logger.debug(
			'Selected branch: ['
				.. branch
				.. '] '
				.. 'repository: ['
				.. repository.name
				.. ']'
		)

		local project_branch = branch_lookup[branch]
		config.set_project_branch(project_branch)
		config.set_project_repository(repository)
		if not config.get_project_config().mode then
			M.select_mode()
		end
	end
	select_list(branches, title, on_select, separator, nil, bottom_text)
end

local function select_mode()
	local items = {
		Mode.CurrentBuffer,
		Mode.Skip,
	}
	local title = 'Select Dev Mode'
	local on_select = function(source)
		if source == 'Current Buffer' then
			config.set_project_mode(Mode.CurrentBuffer)
		elseif source == 'Specified File' then
			config.set_project_mode(Mode.SpecifiedFile)
		else
			config.set_project_mode(Mode.Skip)
		end
		vim.notify(
			'Selected mode: [' .. config.get_project_config().mode .. ']',
			vim.log.levels.INFO
		)
	end
	select_list(items, title, on_select)
end

local function select_pipeline()
	local names = {}
	local name_lookup = {}
	local respone = api.list_pipeline()
	local current_pipeline = config.get_project_config().pipeline
	for _, v in pairs(respone.data.body.value) do
		if current_pipeline and current_pipeline.id == v.id then
			table.insert(names, v.name .. ' (active)')
		else
			table.insert(names, v.name)
		end
		name_lookup[v.name] = v.id
	end
	local title = 'Select Pipeline'
	local separator = '[' .. #names .. ' pipelines found]'
	local on_select = function(choice)
		choice = ui.clear_postfix(choice)
		local pipeline_id = name_lookup[choice]
		vim.notify(
			'Selected pipeline: [' .. choice .. '] with id: [' .. pipeline_id .. ']',
			vim.log.levels.INFO
		)

		local pipeline = api.get_pipeline(pipeline_id)
		if not pipeline.configuration.repository then
			vim.notify('Failed to get repository connection id', vim.log.levels.ERROR)
			return
		end

		if pipeline.configuration.repository == vim.NIL then
			vim.notify(
				'Repository not found for the selected pipeline: [' .. choice .. ']',
				vim.log.levels.ERROR
			)
			return
		end
		if pipeline.configuration.repository.type ~= 'azureReposGit' then
			vim.notify('Only Azure Repos Git is supported', vim.log.levels.ERROR)
			return
		end

		config.set_project_pipeline(pipeline)
		local repository_id = pipeline.configuration.repository.id
		select_branch(repository_id)
	end

	select_list(names, title, on_select, separator)
end

-- select the branch for the selected pipeline
function M.select_branch()
	async.run(function()
		if config.get_project_config().pipeline == nil then
			vim.notify('Pipeline not selected', vim.log.levels.ERROR)
			M.select_pipeline()
			return
		end
		select_branch(
			config.get_project_config().pipeline.configuration.repository.id
		)
	end)
end

-- preview and validate the selected pipeline
function M.preview()
	async.run(function()
		validate(true)
	end)
end

-- validate the selected pipeline
function M.validate()
	async.run(function()
		validate(false)
	end)
end

-- show the project settings
function M.show_settings()
	async.run(show_settings)
end

-- select the dev mode
function M.select_mode()
	async.run(select_mode)
end

-- select pipeline
function M.select_pipeline()
	async.run(select_pipeline)
end

return M
