local config = require("bazel-tools.config")
local refresh = require("bazel-tools.refresh")

local M = {}

local BAZEL_CONFIG_PATTERNS = {
  "BUILD", "BUILD.bazel", "MODULE.bazel",
  "WORKSPACE", "WORKSPACE.bazel", "*.bzl",
}

function M.setup()
  local cfg = config.current.auto_refresh
  if not cfg.enabled then
    return
  end

  local group = vim.api.nvim_create_augroup("BazelToolsAutoRefresh", { clear = true })
  local targets = config.current.refresh_targets
  local debounce_ms = cfg.debounce_ms

  for name, tcfg in pairs(targets) do
    if tcfg.target and tcfg.patterns and #tcfg.patterns > 0 then
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = tcfg.patterns,
        group = group,
        callback = function()
          refresh.request_refresh(name, tcfg, debounce_ms)
        end,
      })
    end
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = BAZEL_CONFIG_PATTERNS,
    group = group,
    callback = function()
      for name, tcfg in pairs(targets) do
        if tcfg.target then
          refresh.request_refresh(name, tcfg, debounce_ms)
        end
      end
    end,
  })
end

return M
