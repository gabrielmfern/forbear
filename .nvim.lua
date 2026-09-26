local root = vim.fn.getcwd()
local ns = vim.api.nvim_create_namespace("jai_build")
local severities = {
  Error = vim.diagnostic.severity.ERROR,
  Warning = vim.diagnostic.severity.WARN,
  Info = vim.diagnostic.severity.INFO,
}
local output_buf

local function build(show_output)
  vim.cmd("silent! wall")
  vim.system({ "jai-linux", "build.jai" }, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      vim.diagnostic.reset(ns)
      local output = result.stdout .. result.stderr
      local diagnostics = {}
      local last
      for line in output:gmatch("[^\n]+") do
        local file, lnum, col, kind, message = line:match("^(.+%.jai):(%d+),(%d+): (%a+): (.*)$")
        if file then
          local bufnr = vim.fn.bufadd(file)
          diagnostics[bufnr] = diagnostics[bufnr] or {}
          last = {
            lnum = tonumber(lnum) - 1,
            col = tonumber(col) - 1,
            severity = severities[kind],
            message = message,
            source = "jai",
          }
          table.insert(diagnostics[bufnr], last)
        elseif last and line:match("^%s*%^+%s*$") then
          last.end_col = last.col + #line:match("%^+")
          last = nil
        end
      end
      for bufnr, list in pairs(diagnostics) do
        vim.diagnostic.set(ns, bufnr, list)
      end
      if output_buf and vim.api.nvim_buf_is_valid(output_buf) then
        vim.api.nvim_buf_delete(output_buf, { force = true })
      end
      if result.code == 0 then
        vim.notify("jai: build ok")
      else
        vim.notify("jai: build failed", vim.log.levels.ERROR)
      end
      if show_output then
        output_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[output_buf].bufhidden = "wipe"
        vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, vim.split(vim.trim(output), "\n"))
        vim.api.nvim_open_win(output_buf, false, { split = "below", win = -1 })
      end
    end)
  end)
end

vim.keymap.set("n", "<F5>", function() build(false) end)
vim.keymap.set("n", "<F6>", function() build(true) end)
