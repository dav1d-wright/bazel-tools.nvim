local session = require("bazel-tools.session")

local M = {
  build_target = nil,
  run_target = nil,
  test_target = nil,
  config = "",
  args = {},
}

local function save()
  session.save(vim.fn.getcwd(), {
    build_target = M.build_target,
    run_target = M.run_target,
    test_target = M.test_target,
    config = M.config,
    args = M.args,
  })
end

function M.load()
  local data = session.load(vim.fn.getcwd())
  M.build_target = data.build_target
  M.run_target = data.run_target
  M.test_target = data.test_target
  M.config = data.config or ""
  -- Copy into a fresh table to strip any cjson array metatable from decoded []
  M.args = {}
  if data.args then
    for k, v in pairs(data.args) do
      M.args[k] = v
    end
  end
end

function M.set_build_target(target)
  M.build_target = target
  save()
end

function M.set_run_target(target)
  M.run_target = target
  save()
end

function M.set_test_target(target)
  M.test_target = target
  save()
end

function M.set_args(target, args_str)
  M.args[target] = args_str
  save()
end

function M.get_args(target)
  if not target then
    return ""
  end
  return M.args[target] or ""
end

function M.set_config(cfg)
  M.config = cfg
  save()
end

function M.get_config_display()
  return M.config == "" and "default" or M.config
end

function M.get_build_target_display()
  return M.build_target or "[none]"
end

function M.get_run_target_display()
  return M.run_target or "[none]"
end

function M.get_test_target_display()
  return M.test_target or "[none]"
end

return M
