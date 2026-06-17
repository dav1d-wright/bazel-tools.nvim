local config = require("bazel-tools.config")

local M = {}

local target_exists_cache = {}
local timers = {}
local running = {}

function M._check_target_exists(target, callback)
  local cached = target_exists_cache[target]
  if cached ~= nil then
    callback(cached)
    return
  end

  vim.system(
    { config.current.bazel_command, "query", target },
    { cwd = vim.fn.getcwd(), text = true },
    function(result)
      vim.schedule(function()
        target_exists_cache[target] = (result.code == 0)
        callback(result.code == 0)
      end)
    end
  )
end

function M._run_target(name, tcfg)
  if running[name] then
    return
  end
  running[name] = true
  vim.notify("Refreshing " .. (tcfg.output or name) .. "...", vim.log.levels.INFO)

  vim.system(
    { config.current.bazel_command, "run", tcfg.target },
    { cwd = vim.fn.getcwd(), text = true },
    function(result)
      vim.schedule(function()
        running[name] = false
        if result.code == 0 then
          vim.notify(
            (tcfg.output or name) .. " refreshed",
            vim.log.levels.INFO
          )
          vim.api.nvim_exec_autocmds("User", {
            pattern = "BazelRefreshComplete:" .. name,
            data = { name = name, target = tcfg.target, output = tcfg.output },
          })
        else
          local stderr = (result.stderr or ""):sub(1, 200)
          vim.notify(
            (tcfg.output or name) .. " refresh failed: " .. stderr,
            vim.log.levels.WARN
          )
        end
      end)
    end
  )
end

function M.request_refresh(name, tcfg, debounce_ms)
  if running[name] then
    return
  end

  local cached = target_exists_cache[tcfg.target]
  if cached == false then
    return
  end
  if cached == nil then
    M._check_target_exists(tcfg.target, function() end)
    return
  end

  if timers[name] then
    timers[name]:stop()
  else
    timers[name] = vim.uv.new_timer()
  end
  timers[name]:start(debounce_ms, 0, vim.schedule_wrap(function()
    M._run_target(name, tcfg)
  end))
end

function M.run_initial(name, tcfg)
  if not tcfg.output then
    return
  end
  local output_path = vim.fn.getcwd() .. "/" .. tcfg.output
  if vim.uv.fs_stat(output_path) then
    return
  end
  M._check_target_exists(tcfg.target, function(exists)
    if exists then
      M._run_target(name, tcfg)
    end
  end)
end

return M
