# azure-pipelines.nvim (UNDER DEVELOPMENT)

Azure Pipelines integration for Neovim

## Motivation

When working with Azure Pipelines, there are scenarios where the LSP server not able to provide validation. 

For example:
- Detecting duplicate step/job names
- Validating pipeline templates which are used in your pipeline

In these situations, pipeline errors are only revealed when you actually run the pipeline. 
This plugin aims to address these limitations by leveraging the Azure DevOps API to provide:

- Pipeline validation 
- Pipeline previews (shows the full pipelines) 

So you can catch thease kind of errors in your editor before running the pipeline.

## Features

- Validate pipeline
- Preview the full pipline
- Configure Azure Pipelines LSP automatically

## Installation
```
{
  'atm1020/azure-pipelines.nvim'
}
```
## Setup
```lua
require('azure-pipelines').setup()
```

## Usage

### Setup azure-devop api
select/save/delete the Azure DevOps API configuration.
```lua
require('azure-pipelines').select_api_config()
```

The api configuration is saved globally and can be connect to multiple projects.
The configuration  which is marked as `active` will be used for the current project.


### Select pipeline
Select a pipeline from your Azure DevOps project.

```lua
lua require("azure-pipelines").select_pipeline()
```

### Select branch
Select a branch for the selected pipeline. 


```lua
lua require("azure-pipelines").select_branch()
```
### Select dev mode
Select a dev mode for the selected pipeline.

Modes:
- `Skip`: Dosen't override the pipeline yaml file use the original file from the selected branch
- `Current Buffer`: Send the current buffer content as the pipeline yaml file.

```lua
lua require("azure-pipelines").select_mode()
```

### Show project settings
Show the current project settings, which includes the selected pipeline, branch, and dev mode.

```lua
lua require("azure-pipelines").show_project_settings()
```

### Validate pipeline
Validate the selected pipeline.

```lua
lua require("azure-pipelines").validate()
```

### Preview pipeline
Validate the selected pipeline and show the full pipeline if there are no errors.
```lua
lua require("azure-pipelines").preview()
```
