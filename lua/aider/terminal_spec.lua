local luv = require('luv')
local mock = require('luassert.mock')

describe("Aider Terminal Module", function()
    local Aider, mockConfig, mockTerminal

    before_each(function()
        -- Reset mocks before each test
        package.loaded['aider.terminal'] = nil
        package.loaded['toggleterm.terminal'] = nil
        package.loaded['aider'] = nil

        -- Create mock config
        mockConfig = {
            float_opts = {},
            auto_insert = true,
            dark_mode = false,
            aider_args = "",
            watch_files = false,
            toggleterm = {
                direction = "float",
                size = function() return 20 end,
                float_opts = {}
            },
            notify = function(msg, level, opts) end,
            after_update_hook = nil
        }

        -- Mock toggleterm.terminal
        mockTerminal = {
            Terminal = {
                new = function(self, opts)
                    return {
                        cmd = opts.cmd,
                        spawn = function() end,
                        send = function() end,
                        open = function() end,
                        close = function() end,
                        is_open = function() return false end,
                        set_mode = function() end
                    }
                end
            }
        }

        -- Mock require functions
        _G.require = function(module)
            if module == 'toggleterm.terminal' then
                return mockTerminal
            elseif module == 'aider' then
                return { config = mockConfig }
            end
            return require(module)
        end

        -- Load the actual module
        Aider = require('aider.terminal')
    end)

    describe("clean_output function", function()
        local clean_output = require('aider.terminal').clean_output

        it("should remove EOF delimiters", function()
            local input = "Some text {EOF marker}"
            local result = clean_output(input)
            assert.are.equal("Some text ", result)
        end)

        it("should remove ANSI escape sequences", function()
            local input = "\27[31mRed text\27[0m"
            local result = clean_output(input)
            assert.are.equal("Red text", result)
        end)

        it("should remove empty lines", function()
            local input = "   \n"
            local result = clean_output(input)
            assert.are.equal("", result)
        end)
    end)

    describe("command generation", function()
        it("should generate correct command with default settings", function()
            local cmd = Aider.command()
            assert.is_string(cmd)
            assert.is_not_nil(cmd:find("aider"))
            assert.is_not_nil(cmd:find("--no-pretty"))
            assert.is_not_nil(cmd:find("--auto-test"))
        end)

        it("should include dark mode when enabled", function()
            mockConfig.dark_mode = true
            local cmd = Aider.command()
            assert.is_not_nil(cmd:find("--dark-mode"))
        end)

        it("should include watch files when enabled", function()
            mockConfig.watch_files = true
            local cmd = Aider.command()
            assert.is_not_nil(cmd:find("--watch-files"))
        end)
    end)

    describe("terminal management", function()
        it("should create a terminal instance", function()
            local term = Aider.terminal()
            assert.is_not_nil(term)
        end)

        it("should load files", function()
            local files = {"file1.lua", "file2.lua"}
            local term = mock.mock(Aider.terminal())
            Aider.load_files(files)
            assert.stub(term.send).was_called_with(term, "/add file1.lua file2.lua")
        end)

        it("should send commands", function()
            local term = mock.mock(Aider.terminal())
            Aider.send_command("test command")
            assert.stub(term.send).was_called()
        end)
    end)

    describe("ask functionality", function()
        it("should handle empty prompts", function()
            local notifySpy = mock.mock(mockConfig, "notify")
            Aider.ask("")
            assert.stub(notifySpy).was_called_with("No input provided", vim.log.levels.WARN)
        end)

        it("should send ask command with prompt", function()
            local term = mock.mock(Aider.terminal())
            Aider.ask("Test prompt")
            assert.stub(term.send).was_called()
            assert.stub(term.open).was_called()
        end)
    end)
end)
