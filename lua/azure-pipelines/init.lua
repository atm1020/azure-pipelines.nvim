local api = require('azure-pipelines.az_devops_api')
local ui = require('azure-pipelines.ui')
local async = require('plenary.async')

local M = {}

local global_config = {
	schema = 'https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/main/service-schema.json',
	filter = {
		'azure-pipeline*.y*l',
		'.azure*',
		'templates/*',
		'.pipelines/*',
		'/pipelines/*',
	},
	root_pattern = { 'azure-pipeline.yaml', '.git' }
}

local Settings = {
	--- @type Pipeline
	current_pipeline = nil,
	--- @type Branch
	current_pipeline_branch = nil,
	--- @type Mode
	mode = nil,
}

--- @enum Mode
local Mode = {
	CurrentBuffer = 'Current Buffer',
	SpecifiedFile = 'Specified File',
	Skip = 'Skip',
}

--- @param preview boolean
local function validate(preview)
	--- @type string|nil
	local content = nil
	if Settings.current_pipeline == nil then
		error('Pipeline not selected')
	end
	if Settings.mode == Mode.CurrentBuffer then
		local bufnr = vim.api.nvim_get_current_buf()
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		content = table.concat(lines, '\n')
	elseif M.mode == Mode.SpecifiedFile then
		vim.notify('Select the file to preview', vim.log.levels.INFO)
		-- TODO
	end
	async.run(function()
		local resp = api.preview(
			Settings.current_pipeline.id,
			Settings.current_pipeline_branch.name,
			content
		)
		if resp.status ~= 200 then
			local err_msg = resp.body.message
			if resp.status ~= 400 then
				err_msg = resp.body
			end
			ui.error_msg_popup(err_msg)
		elseif preview then
			local yaml_lines = vim.split(resp.body.finalYaml, '\n')
			ui.pipeline_preview_popup(yaml_lines, Settings.current_pipeline.name)
		else
			vim.notify('Pipeline is valid', vim.log.levels.INFO)
		end
	end)
end

--- @param pipeline_id string
local function select_branch(pipeline_id)
	local data = api.search_branch(pipeline_id)
	local branches = {}
	local branch_lookup = {}
	for _, v in pairs(data) do
		table.insert(branches, v.name)
		branch_lookup[v.name] = data
	end
	ui.select_list(branches, 'Select Branch', function(branch)
		vim.notify('Selected branch: [' .. branch .. ']', vim.log.levels.INFO)
		Settings.current_pipeline_branch = branch_lookup[branch]
		if not Settings.mode then
			M.select_mode()
		end
	end, '[' .. #branches .. ' branches found]')
end

-- select the branch for the selected pipeline
function M.select_branch()
	if Settings.current_pipeline == nil then
		vim.notify('Pipeline not selected', vim.log.levels.ERROR)
		M.select()
		return
	end
	select_branch(Settings.current_pipeline.configuration.repository.id)
end

-- preview the selected pipeline
function M.preview()
	validate(true)
end

-- validate the selected pipeline
function M.validate()
	validate(false)
end

function M.select_mode()
	ui.select_list(
		{
			'Current Buffer',
			-- 'Specified File',
			'Skip',
		},
		'Select dev mode',
		function(source)
			if source == 'Current Buffer' then
				Settings.mode = Mode.CurrentBuffer
			elseif source == 'Specified File' then
				Settings.mode = Mode.SpecifiedFile
			else
				Settings.mode = Mode.Skip
			end
			vim.notify(
				'Selected mode: [' .. Settings.mode .. ']',
				vim.log.levels.INFO
			)
		end
	)
end

function M.select_pipeline()
	local names = {}
	local name_lookup = {}
	async.run(function()
		local respone = api.list_pipeline()
		for _, v in pairs(respone.data.body.value) do
			table.insert(names, v.name)
			name_lookup[v.name] = v.id
		end
		ui.select_list(names, 'Select Pipeline', function(choice)
			local pipeline_id = name_lookup[choice]
			vim.notify(
				'Selected pipeline: [' .. choice .. '] with id: [' .. pipeline_id .. ']',
				vim.log.levels.INFO
			)

			local pipeline = api.get_pipeline(pipeline_id)
			Settings.current_pipeline = pipeline
			if not pipeline.configuration.repository then
				vim.notify(
					'Failed to get repository connection id',
					vim.log.levels.ERROR
				)
				return
			end

			if pipeline.configuration.repository.type ~= 'azureReposGit' then
				vim.notify('Only Azure Repos Git is supported', vim.log.levels.ERROR)
				return
			end

			local connection = pipeline.configuration.repository.id
			select_branch(connection)
		end, '[' .. #names .. ' pipelines found]')
	end)
end

function M.show_settings()
	vim.notify('Settings \n' .. vim.inspect({ Settings }), vim.log.levels.INFO)
end

--- @param custom_config UserConfig
function M.setup(custom_config)
	local config =
		vim.tbl_deep_extend('force', global_config, custom_config or {})
	local lspconfig = require('lspconfig')
	lspconfig.azure_pipelines_ls.setup({
		root_dir = lspconfig.util.root_pattern(config.root_pattern),
		settings = {
			yaml = {
				schemas = {
					[config.schema] = config.filter,
				},
			},
		},
	})
end

return M

--- @class UserConfig
--- @field schema string
--- @field filter string[]
