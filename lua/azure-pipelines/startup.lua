local curl = require('plenary.curl')
local Path = require('plenary.path')
local logger = require('azure-pipelines.utils.logger')

local M = {}

local service_schema_sha = 'c9e33c280403692f587051dfffa753ac58b9ceac'
local config_path = vim.fn.stdpath('data')
	.. '/azure-pipelines-service-schema'
	.. service_schema_sha
	.. '.json'
M.config = {}

local global_config = {
	schema = config_path,
	filter = {
		'azure-pipeline*.y*l',
		'.azure*',
		'templates/*',
		'.pipelines/*',
		'/pipelines/*',
	},
	root_pattern = { 'azure-pipeline.yaml', '.git' },
	log_level = vim.log.levels.INFO,
}

local function download_service_schema()
	local url = 'https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/'
		.. service_schema_sha
		.. '/service-schema.json'
	curl.get(url, {
		callback = function(response)
			local file = io.open(config_path, 'w')
			assert(file, 'Failed to open file')
			file:write(response.body)
			file:close()
			logger.info('Schema downloaded  sha:' .. service_schema_sha)
		end,
	})
end
--- @param custom_config UserConfig|nil
function M.setup(custom_config)
	local packages = {
		{
			name = 'yaml-language-server',
			version = '0.15.0',
		},
		{
			name = 'azure-pipelines-language-server',
			version = '0.8.0',
		},
	}

	local mason_ui = require('mason.ui')
	local mason_reg = require('mason-registry')
	for _, pkg in ipairs(packages) do
		local _pkg = mason_reg.get_package(pkg.name)
		local is_installed = _pkg:is_installed()
		if not is_installed then
			mason_ui.open()
			_pkg:install({
				version = pkg.version,
				force = true,
			})
		end
	end

	local config =
		vim.tbl_deep_extend('force', global_config, custom_config or {})
	local lspconfig = require('lspconfig')
	if not Path:new(config.schema):exists() then
		-- TODO remove old service-schema.json
		download_service_schema()
	end

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
--- @field schema string|nil
--- @field filter string[]|nil
