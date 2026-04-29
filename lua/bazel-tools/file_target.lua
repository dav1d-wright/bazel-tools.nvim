local config = require("bazel-tools.config")

local M = {}

function M.find_package(filepath)
  local cwd = vim.fn.getcwd()
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local found = vim.fs.find({ "BUILD.bazel", "BUILD" }, {
    path = dir,
    upward = true,
    stop = vim.fn.fnamemodify(cwd, ":h"),
  })
  if #found == 0 then
    return nil
  end
  local build_dir = vim.fn.fnamemodify(found[1], ":h")
  local pkg = build_dir:sub(#cwd + 2)
  return pkg
end

function M.resolve_target(filepath, callback)
  local cfg = config.current
  local cwd = vim.fn.getcwd()
  local relative = filepath:sub(#cwd + 2)
  local pkg = M.find_package(filepath)
  if not pkg then
    return vim.notify("No BUILD file found for " .. relative, vim.log.levels.WARN)
  end

  local file_in_pkg = pkg == "" and relative or relative:sub(#pkg + 2)
  local file_label = "//" .. pkg .. ":" .. file_in_pkg
  local query_str = string.format('kind("rule", rdeps(%s, %s))', cfg.query_scope, file_label)

  vim.system(
    { cfg.bazel_command, "query", query_str, "--output=label" },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          return vim.notify("bazel query failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
        end
        local targets = {}
        for line in result.stdout:gmatch("[^\n]+") do
          table.insert(targets, line)
        end
        if #targets == 0 then
          return vim.notify("No targets own " .. relative, vim.log.levels.WARN)
        elseif #targets == 1 then
          callback(targets[1])
        else
          vim.ui.select(targets, { prompt = "Multiple targets own this file:" }, function(choice)
            if choice then
              callback(choice)
            end
          end)
        end
      end)
    end
  )
end

return M
