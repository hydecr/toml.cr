require "../spec_helper"

def tokenize(input)
  lexer = TOML::Lexer.new(input)
  {lexer, lexer.tokenize}
end

Spectator.describe TOML::Lexer do
  describe ".tokenize" do
    it "returns an array of tokens for a TOML input" do
      input = <<-TOML
      a = "b"
      TOML
      _, tokens = tokenize(input)
      expect(tokens).to be_a(Array(TOML::Token))
    end

    it "returns an empty array for an empty input" do
      input = ""
      _, tokens = tokenize(input)
      expect(tokens).to eq([] of TOML::Token)
    end

    it "raises an error for an invalid input" do
      input = "a = b"
      expect_raises(TOML::TokenizationError) do
        tokenize(input)
      end
    end

    it "parses valid floats" do
      input = <<-TOML
      pi = 3.14159
      negative = -10.0
      underscored_pi = 3_00.14_159
      underscored_negative = -1_0.0_90
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[2][0]).to eq(:float)
      expect(lexer.token_value(tokens[2])).to eq("3.14159")
      expect(tokens[5][0]).to eq(:float)
      expect(lexer.token_value(tokens[5])).to eq("-10.0")
      expect(tokens[8][0]).to eq(:float)
      expect(lexer.token_value(tokens[8])).to eq("3_00.14_159")
      expect(tokens[11][0]).to eq(:float)
      expect(lexer.token_value(tokens[11])).to eq("-1_0.0_90")
    end

    it "errors on invalid floats" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = 3.14.159")
      end
    end

    it "parses valid integers" do
      input = <<-TOML
      simple = 42
      negative = -42
      simple_underscored = 230_0_0
      long_underscored = 10_000_000_010
      negative_underscored = -10_0_0
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[2][0]).to eq(:integer)
      expect(lexer.token_value(tokens[2])).to eq("42")
      expect(tokens[5][0]).to eq(:integer)
      expect(lexer.token_value(tokens[5])).to eq("-42")
      expect(tokens[8][0]).to eq(:integer)
      expect(lexer.token_value(tokens[8])).to eq("230_0_0")
      expect(tokens[11][0]).to eq(:integer)
      expect(lexer.token_value(tokens[11])).to eq("10_000_000_010")
      expect(tokens[14][0]).to eq(:integer)
      expect(lexer.token_value(tokens[14])).to eq("-10_0_0")
    end

    it "errors on invalid integers" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = 42_0_0_")
      end
    end

    it "parses valid booleans" do
      input = <<-TOML
      true = true
      false = false
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[2][0]).to eq(:bool)
      expect(lexer.token_value(tokens[2])).to eq("true")
      expect(tokens[5][0]).to eq(:bool)
      expect(lexer.token_value(tokens[5])).to eq("false")
    end

    it "errors on invalid booleans" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = True")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = False")
      end
    end

    it "parses valid datetimes" do
      input = <<-TOML
      lt1 = 07:32:00
      lt2 = 00:32:00.999999

      ld1 = 1979-05-27

      ldt1 = 1979-05-27T07:32:00
      ldt2 = 1979-05-27T00:32:00.999999

      odt1 = 1979-05-27T07:32:00Z
      odt2 = 1979-05-27T00:32:00-07:00
      odt3 = 1979-05-27T00:32:00.999999-07:00
      odt4 = 1979-05-27 07:32:00Z
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[2][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[2])).to eq("07:32:00")
      expect(tokens[5][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[5])).to eq("00:32:00.999999")
      expect(tokens[8][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[8])).to eq("1979-05-27")
      expect(tokens[11][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[11])).to eq("1979-05-27T07:32:00")
      expect(tokens[14][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[14])).to eq("1979-05-27T00:32:00.999999")
      expect(tokens[17][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[17])).to eq("1979-05-27T07:32:00Z")
      expect(tokens[20][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[20])).to eq("1979-05-27T00:32:00-07:00")
      expect(tokens[23][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[23])).to eq("1979-05-27T00:32:00.999999-07:00")
      expect(tokens[26][0]).to eq(:datetime)
      expect(lexer.token_value(tokens[26])).to eq("1979-05-27 07:32:00Z")
    end

    it "errors on invalid datetimes" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = 1979-05-27T07:32:00.999999-07:00:00")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = 05-27-1979")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = 1979-05-27T07:32")
      end
    end

    it "parses valid arrays" do
      input = <<-TOML
      empty = []
      simple = [1, 2, 3]
      nested = [[1, 2], [3, 4, 5]]
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[2][0]).to eq(:array)
      expect(lexer.token_value(tokens[2])).to eq("[]")
      expect(tokens[5][0]).to eq(:array)
      expect(lexer.token_value(tokens[5])).to eq("[1, 2, 3]")
      expect(tokens[11][0]).to eq(:array)
      expect(lexer.token_value(tokens[11])).to eq("[[1, 2], [3, 4, 5]]")
    end

    it "errors on invalid arrays" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = [1, 2, 3")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = 1, 2, 3]")
      end
    end

    it "parses valid standard tables" do
      input = <<-TOML
      [table]
      [table.subtable]
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[0][0]).to eq(:std_table)
      expect(lexer.token_value(tokens[0])).to eq("[table]")
      expect(tokens[2][0]).to eq(:std_table)
      expect(lexer.token_value(tokens[2])).to eq("[table.subtable]")
    end

    it "errors on invalid standard tables" do
      expect_raises(TOML::TokenizationError) do
        tokenize("[table")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("[table.subtable")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("[table.subtable] invalid")
      end
    end

    it "parses valid array tables" do
      input = <<-TOML
      [[table.array]]
      [[table.array]]
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[0][0]).to eq(:array_table)
      expect(lexer.token_value(tokens[0])).to eq("[[table.array]]")
      expect(tokens[2][0]).to eq(:array_table)
      expect(lexer.token_value(tokens[2])).to eq("[[table.array]]")
    end

    it "errors on invalid array tables" do
      expect_raises(TOML::TokenizationError) do
        tokenize("[[table.array]")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("[[table.array]] invalid")
      end
    end

    it "parses valid inline tables" do
      input = <<-TOML
      empty = {}
      simple = { a = 1, b = 2 }
      nested = { a = { b = 1 }, c = 2 }
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[2][0]).to eq(:inline_table)
      expect(lexer.token_value(tokens[2])).to eq("{}")
      expect(tokens[5][0]).to eq(:inline_table)
      expect(lexer.token_value(tokens[5])).to eq("{ a = 1, b = 2 }")
      expect(tokens[14][0]).to eq(:inline_table)
      expect(lexer.token_value(tokens[14])).to eq("{ a = { b = 1 }, c = 2 }")
      expect(tokens[17][0]).to eq(:inline_table)
      expect(lexer.token_value(tokens[17])).to eq("{ b = 1 }")
    end

    it "errors on invalid inline tables" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = { a = 1, b = 2")
      end
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = a = 1, b = 2 }")
      end
    end

    it "fully ignores comments" do
      input = <<-TOML
      # This is a comment
      key = "value" # This is another comment
      # This is a multiline comment
      # that spans multiple lines
      TOML
      lexer, tokens = tokenize(input)
      expect(tokens[1][0]).to eq(:key)
      expect(lexer.token_value(tokens[1])).to eq("key")
      expect(tokens[2][0]).to eq(:string)
      expect(lexer.token_value(tokens[2])).to eq("\"value\"")
    end

    it "ensures comments cannot be assigned" do
      expect_raises(TOML::TokenizationError) do
        tokenize("invalid = # This is a comment")
      end
    end
  end
end
