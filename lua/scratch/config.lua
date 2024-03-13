local slash = require("scratch.utils").Slash()
local M = {}

local DEFAULT_CONFIG_PATH = vim.fn.stdpath("config") .. slash .. "scratch_config.json"

---@alias mode
---| '"n"'
---| '"i"'
---| '"v"'

---@class Scratch.LocalKey
---@field cmd string
---@field key string
---@field modes mode[]

---@class Scratch.LocalKeyConfig
---@field filenameContains string[] as long as the filename contains any one of the string in the list
---@field LocalKeys Scratch.LocalKey[]

local function getConfigFilePath()
  return DEFAULT_CONFIG_PATH
end

-- Read json file and parse to dictionary
local function readConfigFile()
  local configFilePath = getConfigFilePath()

  local file = io.open(configFilePath, "r")
  local json_data = file:read("*all")
  file:close()

  return vim.fn.json_decode(json_data)
end

---comment
---@return {}
function M.getConfig()
  local config = readConfigFile()
  config.scratch_file_dir = vim.fs.normalize(config.scratch_file_dir)
  return config
end

-- TODO: convert to a struct and add type
function M.getConfigRequiresDir(ft)
  local config_data = M.getConfig()
  return config_data.filetype_details[ft] and config_data.filetype_details[ft].requireDir or false
end

---@param ft string
---@return string
function M.getConfigFilename(ft)
  local config_data = M.getConfig()
  return config_data.filetype_details[ft] and config_data.filetype_details[ft].filename
    or tostring(os.date("%y-%m-%d_%H-%M-%S")) .. "." .. ft
end

---@param ft string
---@return string | nil
function M.getConfigSubDir(ft)
  local config_data = M.getConfig()
  return config_data.filetype_details[ft] and config_data.filetype_details[ft].subdir
end

---@return Scratch.LocalKeyConfig[] | nil
function M.getLocalKeys()
  local config_data = M.getConfig()
  return config_data.localKeys
end

---@return boolean
function M.get_use_telescope()
  local config_data = M.getConfig()
  return config_data.use_telescope or false
end

-- Expose editConfig function
function M.editConfig()
  vim.cmd(":e " .. getConfigFilePath())
end

function M.checkConfig()
  vim.notify(vim.inspect(readConfigFile()))
end

return M
