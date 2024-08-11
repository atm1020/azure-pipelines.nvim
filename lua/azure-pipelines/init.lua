local api_config = require('azure-pipelines.api_config')
local pipeline = require('azure-pipelines.pipeline')
local startup = require('azure-pipelines.startup')

local M = {}

--- AzDevops Api Config
M.select_api_config = api_config.select_api_config

--- Pipeline
M.validate = pipeline.validate
M.preview = pipeline.preview
M.select_branch = pipeline.select_branch
M.select_pipeline = pipeline.select_pipeline
M.select_mode = pipeline.select_mode
M.show_settings = pipeline.show_settings

--- setup
M.setup = startup.setup

--- user commands
local commands = {
	['AzurePipelinesValidate'] = pipeline.validate,
	['AzurePipelinesPreview'] = pipeline.preview,
	['AzurePipelinesSelectBranch'] = pipeline.select_branch,
	['AzurePipelinesSelectPipeline'] = pipeline.select_pipeline,
	['AzurePipelinesSelectMode'] = pipeline.select_mode,
	['AzurePipelinesShowSettings'] = pipeline.show_settings,
	['AzurePipelinesSelectApiConfig'] = api_config.select_api_config,
}
for name, func in pairs(commands) do
	vim.api.nvim_create_user_command(name, func, {})
end

return M
