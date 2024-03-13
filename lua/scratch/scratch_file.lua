local M = {}
local config = require("scratch.config")
local slash = require("scratch.utils").Slash()
local utils = require("scratch.utils")
local telescope_status, telescope_builtin = pcall(require, "telescope.builtin")

local function editFile(fullpath)
  local config_data = config.getConfig()
  local cmd = config_data.window_cmd or "edit"
  vim.api.nvim_command(cmd .. " " .. fullpath)
end

local function write_lines_to_buffer(lines)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

local function hasDefaultContent(ft)
  local config_data = config.getConfig()
  return config_data.filetype_details[ft]
    and config_data.filetype_details[ft].content
    and #config_data.filetype_details[ft].content > 0
end

local function hasCursorPosition(ft)
  local config_data = config.getConfig()
  return config_data.filetype_details[ft]
    and config_data.filetype_details[ft].cursor
    and #config_data.filetype_details[ft].cursor.location > 0
end

---@param filename string
function M.createScratchFileByName(filename)
  local config_data = config.getConfig()
  local scratch_file_dir = config_data.scratch_file_dir
  utils.initDir(scratch_file_dir)

  local fullpath = scratch_file_dir .. slash .. filename
  editFile(fullpath)
end

---@param ft string
function M.createScratchFileByType(ft)
  local config_data = config.getConfig()
  local parentDir = config_data.scratch_file_dir
  utils.initDir(parentDir)

  local subdir = config.getConfigSubDir(ft)
  if subdir ~= nil then
    parentDir = parentDir .. slash .. subdir
    utils.initDir(parentDir)
  end

  local fullpath =
    utils.genFilepath(config.getConfigFilename(ft), parentDir, config.getConfigRequiresDir(ft))
  editFile(fullpath)

  if hasDefaultContent(ft) then
    write_lines_to_buffer(config_data.filetype_details[ft].content)
  end

  if hasCursorPosition(ft) then
    vim.api.nvim_win_set_cursor(0, config_data.filetype_details[ft].cursor.location)
    if config_data.filetype_details[ft].cursor.insert_mode then
      vim.api.nvim_feedkeys("a", "n", true)
    end
  end
end

local function getFiletypes()
  local config_data = config.getConfig()
  local combined_filetypes = {}
  for _, ft in ipairs(config_data.filetypes) do
    if not vim.tbl_contains(combined_filetypes, ft) then
      table.insert(combined_filetypes, ft)
    end
  end

  for ft, _ in pairs(config_data.filetype_details) do
    if not vim.tbl_contains(combined_filetypes, ft) then
      table.insert(combined_filetypes, ft)
    end
  end
  return combined_filetypes
end

local function selectFiletypeAndDo(func)
  local filetypes = getFiletypes()

  vim.ui.select(filetypes, {
    prompt = "Select filetype",
    format_item = function(item)
      return item
    end,
  }, function(choosedFt)
    if choosedFt then
      func(choosedFt)
    end
  end)
end

function M.scratch()
  selectFiletypeAndDo(M.createScratchFileByType)
end

function M.scratchWithName()
  vim.ui.input({
    prompt = "Enter the file name: ",
  }, function(filename)
    if filename ~= nil and filename ~= "" then
      M.createScratchFileByName(filename)
    end
  end)
end

function M.openScratch()
  if not telescope_status then
    vim.notify(
      'ScrachOpen needs telescope.nvim or you can just add `"use_telescope: false"` into your config file ot use native select ui'
    )
    return
  end

  telescope_builtin.find_files({
    cwd = config.getConfig().scratch_file_dir,
    attach_mappings = function(prompt_bufnr, map)
      -- TODO: user can customise keybinding
      map("n", "dd", function()
        require("scratch.telescope_actions").delete_item(prompt_bufnr)
      end)

      return true
    end,
  })
end

return M
