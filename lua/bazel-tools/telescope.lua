local config = require("bazel-tools.config")
local query = require("bazel-tools.query")

local M = {}

function M.pick(items, opts, on_choice)
  if config.current.telescope.enabled then
    local ok, _ = pcall(require, "telescope")
    if ok then
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      pickers
        .new({}, {
          prompt_title = opts.prompt or "Select",
          finder = finders.new_table({ results = items }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                on_choice(selection[1])
              end
            end)
            return true
          end,
        })
        :find()
      return
    end
  end
  vim.ui.select(items, opts, on_choice)
end

function M.pick_targets(kind_filter, opts, on_choice)
  query.query_targets(kind_filter, function(targets)
    M.pick(targets, opts, on_choice)
  end)
end

return M
