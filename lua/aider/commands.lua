local terminal = require("aider.terminal")
local selection = require("aider.selection")
local config = require("aider").config
local comments = require("aider.comments")

local M = {}

local function handle_comment_add(prefix)
  vim.ui.input({
    prompt = prefix .. ": ",
  }, function(input)
    if input and input ~= "" then
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local comment_str = vim.bo.commentstring:format(prefix .. " " .. input)
      vim.api.nvim_buf_set_lines(0, line - 1, line - 1, false, { comment_str })
      local current_lines = vim.api.nvim_buf_get_lines(0, line - 1, line, false)
      vim.cmd("silent write")
      vim.defer_fn(function()
        if prefix:sub(3, 3) == "?" then
          if current_lines[1] == comment_str then
            vim.api.nvim_buf_set_lines(0, line - 1, line, false, {})
          end
        end
      end, 5000)
    end
  end)
end

local function handle_ai_comments()
  vim.api.nvim_create_augroup("ReadCommentsTSTree", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = "ReadCommentsTSTree",
    pattern = "*",
    callback = function()
      if terminal.is_running() then
        if terminal.is_open() then
          return
        end
      end

      local bufnr = vim.fn.bufnr("%")
      local matches = comments.buf_comment_matches(bufnr)

      if matches.any then
        local path = vim.api.nvim_buf_get_name(bufnr)
        if not terminal.is_running() then
          vim.defer_fn(function()
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd("silent w")
            end)
          end, 3000)
          terminal.spawn()
        end

        if config.use_git_stash and matches["ai!"] then
          local message = table.concat(matches.comments, "\n")
          M.stash_msg = message
          require("aider.git").stash("Aider.nvim working dir")
        end

        local show_window = false
        if config.auto_show.on_ask and matches["ai?"] then
          show_window = true
        end
        if config.auto_show.on_change_req and matches["ai!"] then
          show_window = true
        end
        if show_window and not terminal.is_open() then
          terminal.toggle_window(nil, nil)
        end
      end
    end,
  })
end

local function handle_aider_send(opt)
  if opt.range == 0 then
    if not opt.args or opt.args == "" then
      vim.notify("Empty input provided", vim.log.levels.WARN)
      return
    end
    terminal.send_command(opt.args)
    return
  end
  -- Get the selected text
  local selected = selection.get_visual_selection_with_header()
  if not selected then
    vim.notify("Failed to get visual selection", vim.log.levels.ERROR)
    return
  end
  -- Combine selection with any additional arguments
  local input = opt.args and opt.args ~= "" and string.format("%s\n%s", opt.args, selected) or selected
  terminal.send_command(input)
end

---@param opt table Command options containing arguments
local function handle_aider_ask(opt)
  local function process_prompt(input)
    if not input or input == "" then
      vim.notify("Empty input provided", vim.log.levels.WARN)
      return
    end
    local selected = selection.get_visual_selection_with_header()
    if not selected then
      vim.notify("Failed to get visual selection", vim.log.levels.ERROR)
      return
    end
    local filepath = vim.api.nvim_buf_get_name(0)
    terminal.add({ filepath })
    terminal.ask(input, selected)
  end

  if #opt.args > 0 then
    process_prompt(opt.args)
  else
    vim.schedule(function()
      vim.ui.input({ prompt = "/ask: " }, function(input)
        process_prompt(input)
      end)
    end)
  end
end

---Create user commands for aider functionality
---@param opts AiderConfig
function M.setup(opts)
  opts = opts or {}
  vim.api.nvim_create_user_command("AiderToggle", function(opt)
    if not opt.args or opt.args == "" then
      terminal.toggle_window(nil, nil)
      return
    end
    terminal.toggle_window(nil, opt.args)
  end, {
    desc = "Toggle Aider window",
    nargs = "?",
    complete = function()
      return { "vertical", "horizontal", "tab", "float" }
    end,
  })

  vim.api.nvim_create_user_command("AiderLoad", function(opt)
    vim.notify("Deprecated: AiderLoad is deprecated. Use AiderAdd instead.", vim.log.levels.WARN)
    local files = opt.fargs
    if #files == 0 then
      files = { vim.api.nvim_buf_get_name(0) }
    end
    terminal.add(files)
  end, {
    nargs = "*",
    desc = "Load files into Aider",
    complete = "file",
  })

  vim.api.nvim_create_user_command("AiderAdd", function(opt)
    local files = opt.fargs
    if #files == 0 then
      files = { vim.api.nvim_buf_get_name(0) }
    end
    terminal.add(files)
  end, {
    nargs = "*",
    desc = "Load files into Aider",
    complete = "file",
  })

  vim.api.nvim_create_user_command("AiderReadOnly", function(opt)
    local files = opt.fargs
    if #files == 0 then
      files = { vim.api.nvim_buf_get_name(0) }
    end
    terminal.read_only(files)
  end, {
    nargs = "*",
    desc = "Load files into Aider",
    complete = "file",
  })

  vim.api.nvim_create_user_command("AiderDrop", function(opt)
    local files = opt.fargs
    if #files == 0 then
      files = { vim.api.nvim_buf_get_name(0) }
    end
    terminal.drop(files)
  end, {
    nargs = "*",
    desc = "Load files into Aider",
    complete = "file",
  })

  vim.api.nvim_create_user_command("AiderHistorySnacks", function()
    local ok, _ = pcall(require, "snacks.picker")
    if not ok then
      vim.notify("Snacks is not installed", vim.log.levels.ERROR)
    end
    require("aider.snacks_picker").aider_changes()
  end, {})

  vim.api.nvim_create_user_command("AiderSend", handle_aider_send, {
    nargs = "*",
    range = true, -- This enables the command to work with selections
    desc = "Send command to Aider",
    bang = true,
    bar = true,
  })

  vim.api.nvim_create_user_command("AiderAsk", handle_aider_ask, {
    range = true,
    nargs = "*",
    bar = true,
    desc = "Send a prompt to the AI with optional visual selection context",
    bang = true,
  })

  vim.api.nvim_create_user_command("AiderSpawn", function()
    terminal.spawn()
  end, {
    range = true,
    nargs = "*",
    desc = "Ask with visual selection",
    bang = true,
  })

  vim.api.nvim_create_user_command("AiderClear", function()
    terminal.clear()
  end, {
    desc = "Clear current Aider terminal",
  })

  vim.api.nvim_create_user_command("AiderClearAll", function()
    terminal.clear_all()
  end, {
    desc = "Clear all Aider terminals",
  })

  vim.api.nvim_create_user_command("AiderComment", function(opt)
    local prefix = opt.bang and "AI!" or "AI"
    handle_comment_add(prefix)
  end, {
    desc = "Add an AI! comment on the current line",
    bang = true,
  })

  vim.api.nvim_create_user_command("AiderCommentAsk", function(opt)
    handle_comment_add("AI?")
  end, {
    desc = "Add an AI! comment on the current line",
    bang = true,
  })

  vim.api.nvim_create_user_command("AiderFixDiagnostics", function(opt)
    local diagnostics = {}
    if opt.range > 0 then
      for line = opt.line1 - 1, opt.line2 - 1 do -- Convert to 0-based indexing
        local line_diags = vim.diagnostic.get(0, { lnum = line })
        vim.list_extend(diagnostics, line_diags)
      end
    else
      diagnostics = vim.diagnostic.get(0)
    end

    local file = vim.api.nvim_buf_get_name(0)
    terminal.add({ file })

    local aider_diag = require("aider.diagnostics")
    local formatted = aider_diag.format(diagnostics)
    local command = string.format("Fix these diagnostics:\nFile: %q:\n%s", file, table.concat(formatted, "\n"))
    terminal.send_command(command)
  end, {
    desc = "Fix diagnostics",
    range = true,
  })

  local function get_git_root()
    local dot_git = vim.fn.finddir(".git", ".;")
    return dot_git ~= "" and vim.fn.fnamemodify(dot_git, ":h") or nil
  end

  local last_git_root = get_git_root()

  vim.api.nvim_create_autocmd("DirChanged", {
    pattern = "*",
    callback = function()
      if terminal.is_running() then
        local current_git_root = get_git_root()
        if current_git_root ~= last_git_root then
          if opts.restart_on_chdir then
            terminal.clear()
          end
          last_git_root = current_git_root
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TermOpen", "TermEnter" }, {
    pattern = "term://*toggleterm*",
    callback = function()
      vim.opt.list = false
      if opts.on_term_open then
        opts.on_term_open()
      end
      if opts.auto_insert then
        vim.cmd("startinsert")
      end
    end,
  })

  if opts.spawn_on_startup then
    vim.schedule(function()
      vim.cmd("AiderSpawn")
    end)
  end

  if opts.spawn_on_comment then
    handle_ai_comments()
  end
end

return M
