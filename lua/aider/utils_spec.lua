local M = require("aider.utils")

describe("comment_matches", function()
  it("should handle nil comments", function()
    local result = M.comment_matches(nil)
    assert.same({
      any = false,
      ["ai?"] = false,
      ["ai!"] = false,
      ["ai"] = false
    }, result)
  end)

  it("should detect exact ai? match", function()
    local result = M.comment_matches({ "ai?" })
    assert.same({
      any = true,
      ["ai?"] = true,
      ["ai!"] = false,
      ["ai"] = false
    }, result)
  end)

  it("should detect exact ai! match", function()
    local result = M.comment_matches({ "ai!" })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = true,
      ["ai"] = false
    }, result)
  end)

  it("should detect exact ai match", function()
    local result = M.comment_matches({ "ai" })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = false,
      ["ai"] = true
    }, result)
  end)

  it("should detect ai? with spaces", function()
    local result = M.comment_matches({ "  ai?  " })
    assert.same({
      any = true,
      ["ai?"] = true,
      ["ai!"] = false,
      ["ai"] = false
    }, result)
  end)

  it("should detect ai! with spaces", function()
    local result = M.comment_matches({ "  ai!  " })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = true,
      ["ai"] = false
    }, result)
  end)

  it("should detect ai with spaces", function()
    local result = M.comment_matches({ "  ai  " })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = false,
      ["ai"] = true
    }, result)
  end)

  it("should detect ai? at start of comment", function()
    local result = M.comment_matches({ "ai? some text" })
    assert.same({
      any = true,
      ["ai?"] = true,
      ["ai!"] = false,
      ["ai"] = false
    }, result)
  end)

  it("should detect ai! at start of comment", function()
    local result = M.comment_matches({ "ai! some text" })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = true,
      ["ai"] = false
    }, result)
  end)

  it("should detect ai at start of comment", function()
    local result = M.comment_matches({ "ai some text" })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = false,
      ["ai"] = true
    }, result)
  end)

  it("should detect ai? at end of comment", function()
    local result = M.comment_matches({ "some text ai?" })
    assert.same({
      any = true,
      ["ai?"] = true,
      ["ai!"] = false,
      ["ai"] = false
    }, result)
  end)

  it("should detect ai! at end of comment", function()
    local result = M.comment_matches({ "some text ai!" })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = true,
      ["ai"] = false
    }, result)
  end)

  it("should detect ai at end of comment", function()
    local result = M.comment_matches({ "some text ai" })
    assert.same({
      any = true,
      ["ai?"] = false,
      ["ai!"] = false,
      ["ai"] = true
    }, result)
  end)

  it("should handle multiple comments", function()
    local result = M.comment_matches({ "ai?", "some text ai!", "ai" })
    assert.same({
      any = true,
      ["ai?"] = true,
      ["ai!"] = true,
      ["ai"] = true
    }, result)
  end)
end)
