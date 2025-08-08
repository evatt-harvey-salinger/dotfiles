local M = {}

-- Treesitter-based comment stripper.
-- Exposed function:
--   M.strip_comments(bufnr, from, to) -> returns an array of cleaned lines (leading indentation preserved)
-- Parameters are 0-based `from` and `to` (inclusive). If not provided, defaults to whole buffer.

local function safe_get_buf_option(bufnr, opt)
  local ok, val = pcall(vim.api.nvim_buf_get_option, bufnr, opt)
  if not ok then return nil end
  return val
end

function M.strip_comments(bufnr, from, to)
  bufnr = bufnr or 0
  from = from or 0
  to = to or (vim.api.nvim_buf_line_count(bufnr) - 1)

  local ft = safe_get_buf_option(bufnr, 'filetype') or vim.bo.filetype

  -- Fallback: if no parser available, return the raw lines so caller can handle fallback
  local has_parser = pcall(function()
    -- use parsers module to check availability
    local parsers = require('nvim-treesitter.parsers')
    return parsers.get_parser(bufnr, ft)
  end)
  if not has_parser then
    return vim.api.nvim_buf_get_lines(bufnr, from, to + 1, false)
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
  if not ok or not parser then
    return vim.api.nvim_buf_get_lines(bufnr, from, to + 1, false)
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return vim.api.nvim_buf_get_lines(bufnr, from, to + 1, false)
  end
  local root = trees[1]:root()

  -- Try a simple query to capture comment nodes. Most tree-sitter grammars expose a
  -- `comment` node name. If this parse fails, bail back to raw lines.
  local query_ok, query = pcall(vim.treesitter.query.parse, ft, '(comment) @c')
  if not query_ok or not query then
    return vim.api.nvim_buf_get_lines(bufnr, from, to + 1, false)
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, from, to + 1, false)
  -- We'll mutate `lines` in place to remove comment text. `lines` is indexed 1..N

  -- Helper to convert absolute 0-based row to index in `lines`
  local function to_index(abs_row)
    return abs_row - from + 1
  end

  for id, node, _ in query:iter_captures(root, bufnr, from, to + 1) do
    local name = query.captures[id]
    if name == 'c' then
      local srow, scol, erow, ecol = node:range()
      -- Skip nodes outside selection
      if erow < from or srow > to then goto continue end
      local rs = math.max(srow, from)
      local re = math.min(erow, to)
      local si = to_index(rs)
      local ei = to_index(re)

      -- Defensive checks
      if si < 1 or si > #lines or ei < 1 or ei > #lines then goto continue end

      if si == ei then
        local line = lines[si]
        -- node:range columns are 0-based; end column is exclusive
        local left = line:sub(1, scol)
        local right = line:sub(ecol + 1)
        lines[si] = left .. right
      else
        -- multi-line comment: keep before scol on first line, after ecol on last line,
        -- wipe out fully-covered middle lines
        lines[si] = lines[si]:sub(1, scol)
        lines[ei] = lines[ei]:sub(ecol + 1)
        for i = si + 1, ei - 1 do lines[i] = '' end
      end
    end
    ::continue::
  end

  -- After removing comment text, remove trailing whitespace but preserve leading indentation.
  for i = 1, #lines do lines[i] = lines[i]:gsub('%s+$', '') end

  -- Filter out lines that contain only indentation (we don't want to send pure-indentation lines)
  local out = {}
  for _, line in ipairs(lines) do
    if line:match('%S') then table.insert(out, line) end
  end

  return out
end

return M
