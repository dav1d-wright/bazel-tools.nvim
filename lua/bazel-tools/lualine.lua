local M = {}

function M.components()
  local bt = require("bazel-tools")
  local icons = require("codicons")

  return {
    config = {
      function()
        return "Bazel: [" .. bt.get_config() .. "]"
      end,
      icon = icons.get("search"),
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelSelectConfig")
        end
      end,
    },

    build_target = {
      function()
        return "[" .. bt.get_build_target() .. "]"
      end,
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelSelectBuildTarget")
        end
      end,
    },

    build_button = {
      function()
        return "Build"
      end,
      icon = icons.get("gear"),
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelBuild")
        end
      end,
    },

    debug_button = {
      function()
        return icons.get("debug")
      end,
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelDebug")
        end
      end,
    },

    run_button = {
      function()
        return icons.get("run")
      end,
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelRun")
        end
      end,
    },

    run_target = {
      function()
        return "[" .. bt.get_run_target() .. "]"
      end,
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelSelectRunTarget")
        end
      end,
    },

    test_button = {
      function()
        return "Test"
      end,
      icon = icons.get("beaker"),
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelTest")
        end
      end,
    },

    test_target = {
      function()
        return "[" .. bt.get_test_target() .. "]"
      end,
      cond = bt.is_bazel_project,
      on_click = function(n, mouse)
        if n == 1 and mouse == "l" then
          vim.cmd("BazelSelectTestTarget")
        end
      end,
    },

    args_display = {
      function()
        return "args: " .. bt.get_run_args()
      end,
      cond = function()
        return bt.is_bazel_project() and bt.get_run_args() ~= ""
      end,
    },
  }
end

return M
