local M = {}

M.dir = vim.fn.stdpath("data") .. "/bazel-tools/"

function M.get_path(cwd)
  return M.dir .. vim.fn.sha256(cwd):sub(1, 12) .. ".json"
end

function M.load(cwd)
  local path = M.get_path(cwd)
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then
    return {}
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    return {}
  end
  return data or {}
end

function M.save(cwd, data)
  vim.fn.mkdir(M.dir, "p")
  local path = M.get_path(cwd)
  local ok, json = pcall(vim.json.encode, data)
  if not ok then
    return
  end
  local f = io.open(path, "w")
  if not f then
    return
  end
  f:write(json)
  f:close()
end

return M
