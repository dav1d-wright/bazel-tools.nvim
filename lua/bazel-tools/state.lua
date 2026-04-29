local M = {
  build_target = nil,
  run_target = nil,
  config = "",
}

function M.get_config_display()
  return M.config == "" and "default" or M.config
end

function M.get_build_target_display()
  return M.build_target or "[none]"
end

function M.get_run_target_display()
  return M.run_target or "[none]"
end

return M
