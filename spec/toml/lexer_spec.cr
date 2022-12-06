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
  end
end
