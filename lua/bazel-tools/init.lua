local M = {}

M._setup_done = false

function M.is_bazel_project()
  return vim.fn.filereadable("MODULE.bazel") == 1
    or vim.fn.filereadable("WORKSPACE") == 1
    or vim.fn.filereadable("WORKSPACE.bazel") == 1
end

function M.is_cmake_project()
  return vim.fn.filereadable("CMakeLists.txt") == 1
end

function M.setup(opts)
  require("bazel-tools.config").setup(opts)
  require("bazel-tools.state").load()
  M._setup_done = true

  local cmds = require("bazel-tools.commands")
  vim.api.nvim_create_user_command("BazelSelectConfig", cmds.select_config, {})
  vim.api.nvim_create_user_command("BazelSelectBuildTarget", cmds.select_build_target, {})
  vim.api.nvim_create_user_command("BazelSelectRunTarget", cmds.select_run_target, {})
  vim.api.nvim_create_user_command("BazelBuild", cmds.build, {})
  vim.api.nvim_create_user_command("BazelRun", cmds.run, {})
  vim.api.nvim_create_user_command("BazelDebug", cmds.debug, {})
  vim.api.nvim_create_user_command("BazelRefreshCompdb", cmds.refresh_compdb, {})
  vim.api.nvim_create_user_command("BazelStopExecutor", cmds.stop_executor, {})
  vim.api.nvim_create_user_command("BazelStopRunner", cmds.stop_runner, {})
end

-- Re-export public API
function M.select_config()
  require("bazel-tools.commands").select_config()
end

function M.select_build_target()
  require("bazel-tools.commands").select_build_target()
end

function M.select_run_target()
  require("bazel-tools.commands").select_run_target()
end

function M.build()
  require("bazel-tools.commands").build()
end

function M.run()
  require("bazel-tools.commands").run()
end

function M.debug()
  require("bazel-tools.commands").debug()
end

function M.refresh_compdb()
  require("bazel-tools.commands").refresh_compdb()
end

function M.stop_executor()
  require("bazel-tools.commands").stop_executor()
end

function M.stop_runner()
  require("bazel-tools.commands").stop_runner()
end

-- State accessors (for lualine)
function M.get_config()
  return require("bazel-tools.state").get_config_display()
end

function M.get_build_target()
  return require("bazel-tools.state").get_build_target_display()
end

function M.get_run_target()
  return require("bazel-tools.state").get_run_target_display()
end

return M
