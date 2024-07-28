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
	root_pattern = { 'azure-pipeline.yaml', '.git' },
	log_level = vim.log.levels.INFO,
}

--- @param custom_config UserConfig
function M.setup(custom_config)
	-- TODO put this in a separate module
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
