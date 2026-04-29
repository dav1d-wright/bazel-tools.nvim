local config = require("bazel-tools.config")

local M = {}

local timer = nil

function M.setup()
  local cfg = config.current.auto_refresh_compdb
  if not cfg.enabled then
    return
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { "BUILD.bazel", "BUILD" },
    group = vim.api.nvim_create_augroup("BazelToolsAutoRefresh", { clear = true }),
    callback = function()
      if timer then
        timer:stop()
      end
      timer = vim.defer_fn(function()
        require("bazel-tools.commands").refresh_compdb()
        timer = nil
      end, cfg.debounce_ms)
    end,
  })
end

return M
