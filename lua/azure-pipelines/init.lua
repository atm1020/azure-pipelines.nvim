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

return M
