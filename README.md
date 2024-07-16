# azure-pipelines.nvim (UNDER DEVELOPMENT)

Azure Pipelines integration for Neovim

## TODO
- [ ] Save the selected pipeline, branch, and mode for each project
- [ ] Store organization, project, and token information in a config file
- [ ] Api error handling

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

### Setup azure-devop api

Add env vars for azure-devops api
```shell
export AZURE_DEVOPS_ORG=<org>
export AZURE_DEVOPS_PROJECT=<project>
export AZURE_DEVOPS_TOKEN=<token>
```

## Usage

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
