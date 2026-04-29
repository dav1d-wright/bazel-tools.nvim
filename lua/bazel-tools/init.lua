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
  require("bazel-tools.autocmds").setup()
  M._setup_done = true

  local cmds = require("bazel-tools.commands")
  vim.api.nvim_create_user_command("BazelSelectConfig", cmds.select_config, {})
  vim.api.nvim_create_user_command("BazelSelectBuildTarget", cmds.select_build_target, {})
  vim.api.nvim_create_user_command("BazelSelectRunTarget", cmds.select_run_target, {})
  vim.api.nvim_create_user_command("BazelSelectTestTarget", cmds.select_test_target, {})
  vim.api.nvim_create_user_command("BazelBuild", cmds.build, {})
  vim.api.nvim_create_user_command("BazelRun", cmds.run, {})
  vim.api.nvim_create_user_command("BazelTest", cmds.test, {})
  vim.api.nvim_create_user_command("BazelDebug", cmds.debug, {})
  vim.api.nvim_create_user_command("BazelSetArgs", cmds.set_args, {})
  vim.api.nvim_create_user_command("BazelBuildCurrentFile", cmds.build_current_file, {})
  vim.api.nvim_create_user_command("BazelRefreshCompdb", cmds.refresh_compdb, {})
  vim.api.nvim_create_user_command("BazelStopExecutor", cmds.stop_executor, {})
  vim.api.nvim_create_user_command("BazelStopRunner", cmds.stop_runner, {})
  vim.api.nvim_create_user_command("BazelStopTester", cmds.stop_tester, {})

  local nav = require("bazel-tools.navigate")
  vim.api.nvim_create_user_command("BazelGotoBuildFile", nav.goto_build_file, {})
  vim.api.nvim_create_user_command("BazelGotoLabel", nav.goto_label, {})
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

function M.select_test_target()
  require("bazel-tools.commands").select_test_target()
end

function M.build()
  require("bazel-tools.commands").build()
end

function M.run()
  require("bazel-tools.commands").run()
end

function M.test()
  require("bazel-tools.commands").test()
end

function M.debug()
  require("bazel-tools.commands").debug()
end

function M.set_args()
  require("bazel-tools.commands").set_args()
end

function M.build_current_file()
  require("bazel-tools.commands").build_current_file()
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

function M.stop_tester()
  require("bazel-tools.commands").stop_tester()
end

function M.goto_build_file()
  require("bazel-tools.navigate").goto_build_file()
end

function M.goto_label()
  require("bazel-tools.navigate").goto_label()
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

function M.get_test_target()
  return require("bazel-tools.state").get_test_target_display()
end

function M.get_run_args()
  local s = require("bazel-tools.state")
  return s.get_args(s.run_target)
end

return M
