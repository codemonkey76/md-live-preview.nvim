local M = {}

local config = {}
local job_id = nil
local last_sent_lines = {}

local function send_message(payload)
  local json = vim.fn.json_encode(payload) .. "\n"

  local sock = vim.loop.new_tcp()
  if not sock then
    vim.notify("❌ Failed to create socket", vim.log.levels.ERROR)
    return
  end

  sock:connect("127.0.0.1", 3001, function(err)
    if err then
      vim.schedule(function()
        vim.notify("❌ Failed to connect: " .. err, vim.log.levels.ERROR)
      end)
      sock:close()
      return
    end

    sock:write(json, function()
      sock:shutdown()
      sock:close()
    end)
  end)
end

local function handle_buffer_change()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for i, line in ipairs(lines) do
    if last_sent_lines[i] ~= line then
      M.send_buffer_change(i - 1, line)
    end
  end
  last_sent_lines = lines
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", {
    verbose = false,
    cmd = "markdown-preview-server",
  }, opts or {})

  vim.api.nvim_create_user_command("MDPreviewStart", M.start, {})
  vim.api.nvim_create_user_command("MDPreviewStop", M.stop, {})
end

function M.start()
  if vim.bo.filetype ~= "markdown" then
    vim.notify("📄 MDPreviewStart can only be used in markdown files", vim.log.levels.WARN)
    return
  end

  if job_id then
    vim.notify(":🔁 Already running", vim.log.levels.WARN)
    return
  end

  job_id = vim.fn.jobstart(config.cmd, {
    stdout_buffered = false,
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= "" then
          vim.notify("🔹 " .. line, vim.log.levels.INFO)
        end
      end
    end,
    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= "" then
          vim.notify("⚠️ " .. line, vim.log.levels.WARN)
        end
      end
    end,
    on_exit = function(_, code, _)
      vim.notify("🛑 Process exited with code: " .. code, vim.log.levels.INFO)
      job_id = nil
    end,
  })

  if config.verbose then
    vim.notify("🚀 Started markdown preview", vim.log.levels.INFO)
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    pattern = "*.md",
    callback = function()
      M.send_cursor()
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    pattern = "*.md",
    callback = function()
      handle_buffer_change()
    end,
  })

  vim.defer_fn(function()
    M.send_init()
  end, 100)
end

function M.stop()
  if job_id then
    vim.fn.jobstop(job_id)
    job_id = nil
    vim.notify("🛑 Stopped markdown preview", vim.log.levels.INFO)
  else
    vim.notify("ℹ️ Not running", vim.log.levels.INFO)
  end
end

function M.send_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  send_message({
    event = "cursor_moved",
    data = {
      cursor = {
        row - 1,
        col,
      },
    },
  })
end

function M.send_init()
  local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  last_sent_lines = content

  send_message({
    event = "init",
    data = {
      content = content,
      cursor = { row - 1, col },
    },
  })
end

function M.send_buffer_change(line, new_text)
  send_message({
    event = "buffer_change",
    data = {
      line = line,
      new_text = new_text,
    },
  })
end
return M
