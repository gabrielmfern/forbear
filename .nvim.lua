---@diagnostic disable: undefined-global

local run_buf = nil

vim.keymap.set("n", "<leader>r", function()
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true })
  end
  vim.cmd("tabnew | terminal zig build run")
  run_buf = vim.api.nvim_get_current_buf()
end, { desc = "Run zig build run in a new tab" })

vim.keymap.set("n", "<leader>s", function()
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true })
    run_buf = nil
  end
end, { desc = "Kill the zig build run terminal" })
