local config = require("bazel-tools.config")
local state = require("bazel-tools.state")
local telescope = require("bazel-tools.telescope")

local M = {}

local function overseer_run(name, cmd)
  local cfg = config.current
  local overseer = require("overseer")
  local task = overseer.new_task({
    name = name,
    cmd = cmd,
    components = {
      { "on_output_quickfix", errorformat = cfg.errorformat, open = false, open_on_exit = "failure" },
      "default",
    },
  })
  task:start()
end

local function build_cmd(subcmd, target)
  local cfg = config.current
  local cmd = { cfg.bazel_command, subcmd }
  if state.config ~= "" then
    table.insert(cmd, "--config=" .. state.config)
  end
  table.insert(cmd, target)
  return cmd
end

function M.select_config()
  local configs = config.read_configs()
  telescope.pick(configs, { prompt = "Bazel config:" }, function(choice)
    if choice then
      state.set_config(choice == "(default)" and "" or choice)
      vim.notify("Bazel config: " .. state.get_config_display())
    end
  end)
end

function M.select_build_target()
  local cfg = config.current
  telescope.pick_targets(cfg.build_kind_filter, { prompt = "Build target:" }, function(choice)
    if choice then
      state.set_build_target(choice)
      vim.notify("Build target: " .. choice)
    end
  end)
end

function M.select_run_target()
  local cfg = config.current
  telescope.pick_targets(cfg.run_kind_filter, { prompt = "Run target:" }, function(choice)
    if choice then
      state.set_run_target(choice)
      vim.notify("Run target: " .. choice)
    end
  end)
end

function M.select_test_target()
  local cfg = config.current
  telescope.pick_targets(cfg.test_kind_filter, { prompt = "Test target:" }, function(choice)
    if choice then
      state.set_test_target(choice)
      vim.notify("Test target: " .. choice)
    end
  end)
end

function M.set_args()
  local target = state.run_target
  if not target then
    return vim.notify("No run target selected", vim.log.levels.WARN)
  end
  local current = state.get_args(target)
  vim.ui.input({ prompt = "Args for " .. target .. ": ", default = current }, function(input)
    if input then
      state.set_args(target, input)
      vim.notify("Args: " .. (input == "" and "(none)" or input))
    end
  end)
end

function M.build()
  if not state.build_target then
    return vim.notify("No build target selected", vim.log.levels.WARN)
  end
  overseer_run("Bazel Build: " .. state.build_target, build_cmd("build", state.build_target))
end

function M.run()
  if not state.run_target then
    return vim.notify("No run target selected", vim.log.levels.WARN)
  end
  local cmd = build_cmd("run", state.run_target)
  local args = state.get_args(state.run_target)
  if args ~= "" then
    table.insert(cmd, "--")
    for arg in args:gmatch("%S+") do
      table.insert(cmd, arg)
    end
  end
  overseer_run("Bazel Run: " .. state.run_target, cmd)
end

function M.test()
  if not state.test_target then
    return vim.notify("No test target selected", vim.log.levels.WARN)
  end
  overseer_run("Bazel Test: " .. state.test_target, build_cmd("test", state.test_target))
end

function M.debug()
  if not state.run_target then
    return vim.notify("No run target selected", vim.log.levels.WARN)
  end

  local cfg = config.current
  local target = state.run_target
  local dbg_config = cfg.dap.build_config

  vim.notify("Building " .. target .. " (" .. dbg_config .. ")...")
  vim.system(
    { cfg.bazel_command, "build", "--config=" .. dbg_config, target },
    { text = true },
    function(build_result)
      if build_result.code ~= 0 then
        vim.schedule(function()
          vim.notify("Debug build failed", vim.log.levels.ERROR)
        end)
        return
      end
      vim.system(
        { cfg.bazel_command, "cquery", "--config=" .. dbg_config, "--output=files", target },
        { text = true },
        function(cq)
          vim.schedule(function()
            local binary = cq.stdout and cq.stdout:match("[^\n]+")
            if not binary then
              return vim.notify("Could not resolve binary path", vim.log.levels.ERROR)
            end
            local args_str = state.get_args(target)
            local dap_args = {}
            if args_str ~= "" then
              for arg in args_str:gmatch("%S+") do
                table.insert(dap_args, arg)
              end
            end
            require("dap").run({
              type = cfg.dap.adapter,
              request = "launch",
              name = "Bazel: " .. target,
              program = binary,
              args = dap_args,
              cwd = vim.fn.getcwd(),
            })
          end)
        end
      )
    end
  )
end

function M.build_current_file()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return vim.notify("No file in current buffer", vim.log.levels.WARN)
  end
  require("bazel-tools.file_target").resolve_target(filepath, function(target)
    overseer_run("Bazel Build: " .. target, build_cmd("build", target))
  end)
end

function M.refresh_compdb()
  local cfg = config.current
  overseer_run(
    "Bazel: refresh compile_commands",
    { cfg.bazel_command, "run", cfg.refresh_compdb_target }
  )
end

function M.stop_executor()
  for _, task in ipairs(require("overseer").list_tasks({ status = "RUNNING" })) do
    if task.name:match("^Bazel Build") or task.name:match("^Bazel: refresh") then
      task:stop()
    end
  end
end

function M.stop_runner()
  for _, task in ipairs(require("overseer").list_tasks({ status = "RUNNING" })) do
    if task.name:match("^Bazel Run") then
      task:stop()
    end
  end
end

function M.stop_tester()
  for _, task in ipairs(require("overseer").list_tasks({ status = "RUNNING" })) do
    if task.name:match("^Bazel Test") then
      task:stop()
    end
  end
end

return M
