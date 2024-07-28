local api_config_path = vim.fn.stdpath('data') .. '/.az-devops-api-config.json'
local project_config_path = vim.fn.stdpath('data') .. '/az-devops-config.json'
local current_project_path = vim.fn.getcwd()

local M = {
	--- @type AzDevopsApiConfig
	cached_api_config = nil,
	--- @type AzurePipelinesProjectConfig
	cached_project_config = nil,
}

--- @param path string
--- @param data table<string, any>
--- @return boolean
local function save_config(path, data)
	local file = io.open(path, 'w')
	assert(file, 'Failed to open file')
	local json_data = vim.fn.json_encode(data)
	assert(json_data, 'Failed to encode JSON')
	file:write(json_data)
	file:close()
	return true
end

--- @return table<string, any>|nil
--- @param path string
local function read_config(path)
	local file = io.open(path, 'r')
	if not file then
		return nil
	end
	local data = file:read('*a')
	local json_data = vim.fn.json_decode(data)
	assert(json_data, 'Failed to decode JSON')
	return json_data
end

--- get project config
--- @return AzurePipelinesProjectConfig
local function get_project_config()
	--- @type AzurePipelinesProjectConfig
	if not M.cached_project_config then
		M.cached_project_config = (read_config(project_config_path) or {})[current_project_path]
			or {}
	end
	return M.cached_project_config
end

--- @param config AzurePipelinesProjectConfig
local function update_project_config(config)
	local full_config = read_config(project_config_path) or {}
	full_config[current_project_path] = config
	save_config(project_config_path, full_config)
	M.cached_project_config = config
end

--- @return AzDevopsApiConfig[]
function M.get_api_config_list()
	return read_config(api_config_path) or {}
end

function M.get_default_api_config_key()
	return get_project_config().active_api_config_key
end

--- @return AzDevopsApiConfig
--- @param key string
function M.get_api_config_by_key(key)
	return M.get_api_config_list()[key]
end

--- @return boolean
--- @param data AzDevopsApiConfig
function M.save_api_config_value(key, data)
	local config = M.get_api_config_list()
	config[key] = data
	return save_config(api_config_path, config)
end

function M.delete_api_config_by_key(key)
	local full_config = read_config(api_config_path) or {}
	full_config[key] = nil
	save_config(api_config_path, full_config)
end

function M.set_api_config_for_current_project(key)
	local config = get_project_config()
	config.active_api_config_key = key
	update_project_config(config)
end

--- @return AzDevopsApiConfig
function M.get_project_api_config()
	local key = get_project_config().active_api_config_key
	return M.get_api_config_by_key(key)
end

--- @return AzurePipelinesProjectConfig
function M.get_project_config()
	return get_project_config()
end

--- @param branch Branch
function M.set_project_branch(branch)
	local config = get_project_config()
	config.branch = {
		name = branch.name,
		objectId = branch.objectId,
	}
	update_project_config(config)
end

--- @param repository GitRepository
function M.set_project_repository(repository)
	local config = get_project_config()
	config.repository = {
		id = repository.id,
		name = repository.name,
		defaultBranch = repository.defaultBranch,
	}
	update_project_config(config)
end

--- @param pipeline Pipeline
function M.set_project_pipeline(pipeline)
	local config = get_project_config()
	config.pipeline = {
		id = pipeline.id,
		name = pipeline.name,
		revision = pipeline.revision,
		url = pipeline.url,
		folder = pipeline.folder,
		configuration = pipeline.configuration,
	}
	update_project_config(config)
end

--- @param mode Mode
function M.set_project_mode(mode)
	local config = get_project_config()
	config.mode = mode
	update_project_config(config)
end

return M

---@class AzDevopsApiConfig
---@field org_name string
---@field project_name string
---@field api_token string

---@class AzurePipelinesProjectConfig
---@field active_api_config_key string
---@field pipeline Pipeline
---@field branch Branch
---@field mode Mode
---@field repository GitRepository
