local M = {}

function M.parse_label(label)
  if not label then
    return nil
  end
  -- //pkg:target
  local pkg, target = label:match("^//([^:]*):(.+)$")
  if pkg then
    return { pkg = pkg, target = target }
  end
  -- //pkg (target = last component of pkg)
  pkg = label:match("^//(.+)$")
  if pkg then
    target = pkg:match("([^/]+)$")
    return { pkg = pkg, target = target }
  end
  -- :target (relative to current package)
  target = label:match("^:(.+)$")
  if target then
    return { pkg = nil, target = target }
  end
  return nil
end

function M.goto_build_file()
  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath == "" then
    return vim.notify("No file in current buffer", vim.log.levels.WARN)
  end
  local cwd = vim.fn.getcwd()
  local dir = vim.fn.fnamemodify(bufpath, ":h")
  local found = vim.fs.find({ "BUILD.bazel", "BUILD" }, {
    path = dir,
    upward = true,
    stop = vim.fn.fnamemodify(cwd, ":h"),
  })
  if #found == 0 then
    return vim.notify("No BUILD file found", vim.log.levels.WARN)
  end
  vim.cmd.edit(found[1])
end

function M.goto_label()
  local word = vim.fn.expand("<cWORD>")
  -- Strip surrounding quotes/commas
  word = word:gsub('["\',]', "")
  local parsed = M.parse_label(word)
  if not parsed then
    return vim.notify("No valid label under cursor", vim.log.levels.WARN)
  end

  local build_dir
  if parsed.pkg then
    build_dir = vim.fn.getcwd() .. "/" .. parsed.pkg
  else
    -- Relative label — use directory of current BUILD file
    build_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
  end

  local build_file
  for _, name in ipairs({ "BUILD.bazel", "BUILD" }) do
    local path = build_dir .. "/" .. name
    if vim.fn.filereadable(path) == 1 then
      build_file = path
      break
    end
  end

  if not build_file then
    return vim.notify("BUILD file not found for " .. word, vim.log.levels.WARN)
  end

  vim.cmd.edit(build_file)
  vim.fn.search('name%s*=%s*"' .. vim.pesc(parsed.target) .. '"', "w")
end

return M
