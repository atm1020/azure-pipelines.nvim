local curl = require('plenary.curl')

-- TODO user config
local organization = os.getenv('AZURE_DEVOPS_ORG')
local project = os.getenv('AZURE_DEVOPS_PROJECT')
local token = os.getenv('AZURE_DEVOPS_TOKEN')

local API = {
	base_url = string.format(
		'https://dev.azure.com/%s/%s/_apis',
		organization,
		project
	),
	headers = {
		Authorization = 'Basic ' .. token,
	},
	api_version = '7.1',
}

--- @return BaseResponse
local function get_base_resposne(response)
	local status_code = response.status
	if status_code >= 400 then
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
	local response = curl.get(url, {
		headers = {
			Authorization = API.headers.Authorization,
		},
		query = set_up_query_param(query),
	})
	return get_base_resposne(response)
end

--- @return BaseResponse
--- @param url string
--- @param body table
--- @param query table|nil
local function post(url, body, query)
	local encoded_body = vim.json.encode(body)
	local response = curl.post(url, {
		headers = {
			Authorization = API.headers.Authorization,
			content_type = 'application/json',
		},
		body = encoded_body,
		query = set_up_query_param(query),
	})
	return get_base_resposne(response)
end

-- local function get_cont_token(headers)
-- 	for _, v in ipairs(headers) do
-- 		if vim.startswith(v, "x-ms-continuationtoken") then
-- 			return vim.split(v, ": ")[2]
-- 		end
-- 	end
-- 	return nil
-- end

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

	return post(url, preview_run_body)
end

return API

--- @class RepositoryConnection
--- @field id string

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
--- @field _links table

--- @class BaseResponse
--- @field status number
--- @field body table
--- @field headers table

--- @class BaseListResponse
--- @field data BaseResponse
--- @field continuation_token string

--- @class Creator
--- @field displayName string
--- @field uniqueName string

--- @class Branch
--- @field creator table
--- @field name string
--- @field objectId string
