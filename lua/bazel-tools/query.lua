local config = require("bazel-tools.config")

local M = {}

function M.query_targets(kind_filter, callback)
  local cfg = config.current
  local cmd = {
    cfg.bazel_command,
    "query",
    string.format('kind("%s", %s)', kind_filter, cfg.query_scope),
    "--output=label",
  }

  vim.system(cmd, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("bazel query failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
      end)
      return
    end

    local targets = {}
    for line in result.stdout:gmatch("[^\n]+") do
      table.insert(targets, line)
    end
    vim.schedule(function()
      callback(targets)
    end)
  end)
end

return M
