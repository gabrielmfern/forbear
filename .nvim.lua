local root = vim.fn.getcwd()
local ns = vim.api.nvim_create_namespace("jai_build")
local severities = {
  Error = vim.diagnostic.severity.ERROR,
  Warning = vim.diagnostic.severity.WARN,
  Info = vim.diagnostic.severity.INFO,
}

vim.keymap.set("n", "<F5>", function()
  vim.cmd("silent! wall")
  vim.system({ "jai-linux", "build.jai" }, { cwd = root, text = true }, function(result)
    vim.schedule(function()
      vim.diagnostic.reset(ns)
      local diagnostics = {}
      local last
      for line in (result.stdout .. result.stderr):gmatch("[^\n]+") do
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
      if result.code == 0 then
        vim.notify("jai: build ok")
      else
        vim.notify("jai: build failed", vim.log.levels.ERROR)
      end
    end)
  end)
end)
