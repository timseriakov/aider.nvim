local M = require("aider.comments")

describe("remove_comment_chars", function()
  local test_cases = {
    {
      desc = "should remove leading comment chars and spaces",
      input = "  -- comment",
      expected = "comment"
    },
    {
      desc = "should remove leading comment chars without spaces",
      input = "--comment",
      expected = "comment"
    },
    {
      desc = "should handle hash comments",
      input = "# comment",
      expected = "comment"
    },
    {
      desc = "should handle slash comments",
      input = "// comment",
      expected = "comment"
    },
    {
      desc = "should handle multiple comment chars",
      input = "//// comment",
      expected = "comment"
    },
    {
      desc = "should handle empty string",
      input = "",
      expected = ""
    },
    {
      desc = "should handle only comment chars",
      input = "//--#",
      expected = ""
    }
  }

  for _, case in ipairs(test_cases) do
    it(case.desc, function()
      local result = M.remove_comment_chars(case.input)
      assert.same(case.expected, result)
    end)
  end
end)

describe("comment_matches", function()
  local test_cases = {
    {
      desc = "should handle nil comments",
      input = nil,
      expected = {
        any = false,
        ["ai?"] = false,
        ["ai!"] = false,
        ["ai"] = false
      }
    },
    {
      desc = "should detect exact ai? match",
      input = { "ai?" },
      expected = {
        any = true,
        ["ai?"] = true,
        ["ai!"] = false,
        ["ai"] = false
      }
    },
    {
      desc = "should detect exact ai! match",
      input = { "ai!" },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = true,
        ["ai"] = false
      }
    },
    {
      desc = "should detect exact ai match",
      input = { "ai" },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = false,
        ["ai"] = true
      }
    },
    {
      desc = "should detect ai? with spaces",
      input = { "  ai?  " },
      expected = {
        any = true,
        ["ai?"] = true,
        ["ai!"] = false,
        ["ai"] = false
      }
    },
    {
      desc = "should detect ai! with spaces",
      input = { "  ai!  " },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = true,
        ["ai"] = false
      }
    },
    {
      desc = "should detect ai with spaces",
      input = { "  ai  " },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = false,
        ["ai"] = true
      }
    },
    {
      desc = "should detect ai? at start of comment",
      input = { "ai? some text" },
      expected = {
        any = true,
        ["ai?"] = true,
        ["ai!"] = false,
        ["ai"] = false
      }
    },
    {
      desc = "should detect ai! at start of comment",
      input = { "ai! some text" },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = true,
        ["ai"] = false
      }
    },
    {
      desc = "should detect ai at start of comment",
      input = { "ai some text" },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = false,
        ["ai"] = true
      }
    },
    {
      desc = "should detect ai? at end of comment",
      input = { "some text ai?" },
      expected = {
        any = true,
        ["ai?"] = true,
        ["ai!"] = false,
        ["ai"] = false
      }
    },
    {
      desc = "should detect ai! at end of comment",
      input = { "some text ai!" },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = true,
        ["ai"] = false
      }
    },
    {
      desc = "should detect ai at end of comment",
      input = { "some text ai" },
      expected = {
        any = true,
        ["ai?"] = false,
        ["ai!"] = false,
        ["ai"] = true
      }
    },
    {
      desc = "should handle multiple comments",
      input = { "ai?", "some text ai!", "ai" },
      expected = {
        any = true,
        ["ai?"] = true,
        ["ai!"] = true,
        ["ai"] = true
      }
    }
  }

  for _, case in ipairs(test_cases) do
    it(case.desc, function()
      local result = M.comment_matches(case.input)
      assert.same(case.expected, result)
    end)
  end
end)
