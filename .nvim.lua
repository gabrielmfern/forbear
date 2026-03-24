---@diagnostic disable: undefined-global

local run_buf = nil

vim.keymap.set("n", "<leader>r", function()
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true })
  end
  local buf_dir = vim.fn.expand("%:p:h")
  local build_zig = vim.fn.findfile("build.zig", buf_dir .. ";")
  if build_zig == "" then
    vim.notify("No build.zig found", vim.log.levels.ERROR)
    return
  end
  local project_dir = vim.fn.fnamemodify(build_zig, ":p:h")
  vim.cmd("tabnew | terminal cd " .. vim.fn.shellescape(project_dir) .. " && zig build run")
  run_buf = vim.api.nvim_get_current_buf()
end, { desc = "Run zig build run in a new tab" })

vim.keymap.set("n", "<leader>s", function()
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true })
    run_buf = nil
  end
end, { desc = "Kill the zig build run terminal" })
