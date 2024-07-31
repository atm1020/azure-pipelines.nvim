local curl = require('plenary.curl')
local config = require('azure-pipelines.config_handler')
local logger = require('azure-pipelines.utils.logger')

local API = {
	api_version = '7.1',
}

function API.init(api_config)
	if not api_config then
		return
	end
	vim.notify('Initializing API', vim.log.levels.INFO, {})
	API.base_url = string.format(
		'https://dev.azure.com/%s/%s/_apis',
		api_config.org_name,
		api_config.project_name
	)

	API.headers = {
		Authorization = 'Basic ' .. api_config.api_token,
	}
end

local function check_config_is_set()
	if not API.base_url then
		error(
			"API initialization failed.\
			Please set up the API configuration for the project (require('azure-pipelines').select_api_config())"
		)
	end
end

--- @return BaseResponse
--- @param response table
--- @param skip_status_codes table<number,boolean>|nil
local function get_base_resposne(response, skip_status_codes)
	local status_code = response.status
	if
		status_code >= 400
		and (not skip_status_codes or not skip_status_codes[status_code])
	then
		error('Failed to fetch data: ' .. vim.inspect({
			status = status_code,
			body = response.body,
		}))
	end

	local ok, body = pcall(vim.json.decode, response.body)
	if not ok then
		error('Failed to decode JSON response: ' .. vim.inspect(response))
	end
	return {
		status = status_code,
		body = body,
		headers = response.headers,
	}
end

--- @return table
--- @param query table|nil
local function set_up_query_param(query)
	if not query then
		query = {}
	end
	query['api-version'] = API.api_version
	return query
end

--- @return BaseResponse
--- @param url string
--- @param query table|nil
local function get(url, query)
	check_config_is_set()
	local headers = {
		Authorization = API.headers.Authorization,
	}
	logger.debug(
		'GET request: ',
		url,
		'query params: ',
		vim.inspect(query),
		'headers: ',
		vim.inspect(headers)
	)
	local response = curl.get(url, {
		headers = headers,
		query = set_up_query_param(query),
	})
	logger.debug('GET response: ', vim.inspect(response))
	return get_base_resposne(response)
end

--- @return BaseResponse
--- @param url string
--- @param body table
--- @param query table|nil
--- @param skip_status_codes table<number,boolean>|nil
local function post(url, body, query, skip_status_codes)
	check_config_is_set()
	local encoded_body = vim.json.encode(body)
	local headers = {
		Authorization = API.headers.Authorization,
		content_type = 'application/json',
	}

	logger.debug(
		'POST request',
		'headers',
		vim.inspect(headers),
		'body: ',
		vim.inspect(body)
	)
	local response = curl.post(url, {
		headers = headers,
		body = encoded_body,
		query = set_up_query_param(query),
	})
	logger.debug('POST response: ', vim.inspect(response))
	return get_base_resposne(response, skip_status_codes)
end

--- @return Pipeline
function API.get_pipeline(pipeline_id)
	local url = string.format('%s/pipelines/%s?', API.base_url, pipeline_id)
	return get(url).body
end

--- @return Branch[]
function API.search_branch(repository_id)
	vim.notify('Fetching branches', vim.log.levels.INFO, {})
	local url =
		string.format('%s/git/repositories/%s/refs?', API.base_url, repository_id)
	local resutl = get(url).body.value
	return resutl
end

--- @return BaseListResponse
function API.list_pipeline()
	vim.notify('Fetching pipelines', vim.log.levels.INFO, {})
	-- local url = ""
	-- if continuation_token == nil then
	-- 	url = string.format("%s/pipelines?&orderBy=asc&$top=%s&api-version=7.1-preview.1",
	-- 		API.base_url, API.list_page_size)
	-- else
	-- 	url = string.format("%s/pipelines?&$top=%s&continuationToken=%s&api-version=7.1-preview.1", API.base_url,
	-- 		API.list_page_size, continuation_token)
	-- end
	local url = string.format('%s/pipelines', API.base_url)
	local response = get(url, {
		orderBy = 'desc',
		['$top'] = 50,
	})
	return {
		data = response,
		continuationtoken = nil,
	}
end

--- @return BaseResponse
--- @param pipeline_id number
--- @param branch_name string
--- @param yamlOverride string|nil
function API.preview(pipeline_id, branch_name, yamlOverride)
	local url =
		string.format('%s/pipelines/%s/preview', API.base_url, pipeline_id)
	local preview_run_body = {
		resources = {
			repositories = {
				['self'] = {
					refName = branch_name,
				},
			},
		},
		previewRun = true,
	}
	if yamlOverride ~= nil then
		preview_run_body['yamlOverride'] = yamlOverride
	end

	return post(url, preview_run_body, nil, { [400] = true })
end

function API.refresh_config()
	API.init(config.get_project_api_config())
end

--- @return GitRepository
function API.get_repository(repository_id)
	local url =
		string.format('%s/git/repositories/%s', API.base_url, repository_id)
	return get(url).body
end

API.refresh_config()

return API

--- @class RepositoryConnection
--- @field id string

--- @class GitRepository
--- @field id string
--- @field name string
--- @field defaultBranch string

--- @class Repository
--- @field id string
--- @field type string

--- @class PipelineConfiguration
--- @field path string
--- @field repository Repository
--- @field type string

--- @class Pipeline
--- @field id number
--- @field name string
--- @field revision number
--- @field url string
--- @field folder string
--- @field configuration PipelineConfiguration

--- @class BaseResponse
--- @field status number
--- @field body table|string
--- @field headers table

--- @class BaseListResponse
--- @field data BaseResponse
--- @field continuation_token string

--- @class Creator
--- @field displayName string
--- @field uniqueName string

--- @class Branch
--- @field name string
--- @field objectId string
