class TOML::Lexer
  def initialize(@content : String)
  end

  def tokenize
    Pegmatite.tokenize(GRAMMAR, @content)
  rescue ex : Pegmatite::Pattern::MatchError
    raise ex.as(TOML::TokenizationError)
  end

  def token_value(token : Token)
    @content[token[1]...token[2]]
  end

  GRAMMAR = Pegmatite::DSL.define do
    # Whitespace
    whitespace = char(' ') | char('\t')
    whitespace_pattern(whitespace.repeat)

    # Newline
    newline = char('\r').maybe >> char('\n')

    # Basic tokens
    l_bracket = char('[')
    r_bracket = char(']')
    l_brace = char('{')
    r_brace = char('}')
    comma = char(',')
    dot = char('.')
    colon = char(':')
    equals = char('=')
    hash = char('#')
    dash = char('-')
    minus = char('-')
    plus = char('+')
    quote = char('"')
    underscore = char('_')
    apostrophe = char('\'')
    quote = char('"')
    triple_quote = quote.repeat_exactly(3)
    double_apostrophe = apostrophe.repeat_exactly(2)
    triple_apostrophe = apostrophe.repeat_exactly(3)
    hex_prefix = str("0x")
    oct_prefix = str("0o")
    bin_prefix = str("0b")
    inf = str("inf")
    nan = str("nan")

    # Alpha
    alpha = range('a', 'z') | range('A', 'Z')

    # Literals
    digit = range('0', '9')
    digit_1_9 = range('1', '9')
    hex_digit = digit | range('a', 'f') | range('A', 'F')
    oct_digit = range('0', '7')
    bin_digit = char('0') | char('1')

    unsigned_dec_int = digit_1_9 >> (underscore.maybe >> digit).repeat
    dec_int = (minus | plus).maybe >> unsigned_dec_int

    hex_int = hex_prefix >> hex_digit >> (underscore.maybe >> hex_digit).repeat
    oct_int = oct_prefix >> oct_digit >> (underscore.maybe >> oct_digit).repeat
    bin_int = bin_prefix >> bin_digit >> (underscore.maybe >> bin_digit).repeat

    integer = (dec_int | hex_int | oct_int | bin_int).named(:integer)

    float_int_part = dec_int
    zero_prefixable_int = digit >> (digit | underscore >> digit).repeat
    frac = dot >> zero_prefixable_int

    float_exp_part = (minus | plus).maybe >> zero_prefixable_int
    exp = (char('e') | char('E')) >> float_exp_part

    special_float = (minus | plus).maybe >> (inf | nan)
    float = ((float_int_part >> (exp | frac >> exp.maybe)) |
             special_float).named(:float)

    # Comment
    non_ascii = range(0x80, 0xD7FF) | range(0xE000, 0x10FFFF)
    non_eol = char(0x09) | range(0x20, 0x7F) | non_ascii
    comment = hash >> non_eol.repeat

    # Booleans
    bool_true = str("true")
    bool_false = str("false")
    bool = (bool_true | bool_false).named(:bool)

    # Basic Strings
    escape = char('\\')
    escape_seq_char = char('b') | char('t') | char('n') | char('f') | char('r') | char('"') | char('\\')
    escaped = escape >> escape_seq_char
    basic_char = whitespace | escaped | char(0x21) | range(0x23, 0x5B) | range(0x5D, 0x10FFFF) | non_ascii

    basic_string = quote >> basic_char.repeat >> quote

    # Multiline Basic Strings
    multiline_basic_string = triple_quote >> (basic_char | newline).repeat >> triple_quote

    # Literal Strings
    literal_char = char(0x09) | range(0x20, 0x26) | range(0x28, 0x7E) | non_ascii
    literal_string = apostrophe >> literal_char.repeat >> apostrophe

    # Multiline Literal Strings
    mll_quotes = apostrophe.repeat_exactly(2)
    mll_content = literal_char | newline
    ml_literal_body = mll_content.repeat >> (mll_quotes >> mll_content.repeat(1)).repeat >> mll_quotes.maybe
    ml_literal_string = triple_apostrophe >> newline.maybe >> ml_literal_body >> triple_apostrophe

    # String
    string = (multiline_basic_string | basic_string | ml_literal_string | literal_string).named(:string)

    # Date / DateTime
    local_date = digit.repeat_exactly(4) >> dash >> digit.repeat_exactly(2) >> dash >> digit.repeat_exactly(2)
    local_time = digit.repeat_exactly(2) >> colon >> digit.repeat_exactly(2) >> colon >> digit.repeat_exactly(2) >> (dot >> digit.repeat).maybe
    local_date_time = (local_date >> char('T') >> local_time).named(:local_date_time)
    offset_date_time = (
      (local_date >> char('T') >> local_time >> (plus | minus) >> digit.repeat_exactly(2) >> colon >> digit.repeat_exactly(2)) |
      (local_date >> char('T') >> local_time >> char('Z'))
    )

    date_time = (offset_date_time | local_date_time | local_date | local_time).named(:date_time)

    # Arrays
    val = declare

    array_open = l_bracket
    array_close = r_bracket
    array_sep = comma
    ws_comment_newline = (whitespace | comment.maybe >> newline).repeat

    array_values = declare
    array_values.define((ws_comment_newline >> val >> ws_comment_newline >> array_sep >> array_values) |
                        (ws_comment_newline >> val >> ws_comment_newline >> array_sep.maybe))

    array = (array_open >> array_values.maybe >> ws_comment_newline >> array_close).named(:array)

    # Key value pairs
    dot_sep = whitespace.repeat >> dot >> whitespace.repeat
    keyval_sep = whitespace.repeat >> equals >> whitespace.repeat

    quoted_key = basic_string | literal_string
    unquoted_key = (alpha | digit | char(0x2D) | char(0x5F)).repeat(1)
    simple_key = quoted_key | unquoted_key
    dotted_key = simple_key >> (dot_sep >> simple_key).repeat(1)

    key = (dotted_key | simple_key).named(:key)
    keyval = (key ^ keyval_sep ^ val).named(:keyval)

    # Standard Table
    std_table_open = l_bracket >> whitespace.repeat
    std_table_close = whitespace.repeat >> r_bracket
    std_table = std_table_open >> key >> std_table_close

    # Inline Table
    inline_table_open = l_brace >> whitespace.repeat
    inline_table_close = whitespace.repeat >> r_brace
    inline_table_sep = whitespace.repeat >> comma >> whitespace.repeat

    inline_table_keyvals = declare
    inline_table_keyvals.define(keyval >> (inline_table_sep >> inline_table_keyvals).maybe)

    inline_table = (inline_table_open >> inline_table_keyvals.maybe >> inline_table_close).named(:inline_table)

    # Array Table
    array_table_open = l_bracket >> l_bracket >> whitespace.repeat
    array_table_close = whitespace.repeat >> r_bracket >> r_bracket

    array_table = (array_table_open >> key >> array_table_close).named(:array_table)

    # Table
    table = (std_table | array_table).named(:table)

    # Values
    val.define(string | bool | array | date_time | inline_table | float | integer)

    # Expressions
    expression = (whitespace.repeat >> table >> whitespace.repeat >> comment.maybe) |
                 (whitespace.repeat >> keyval >> whitespace.repeat >> comment.maybe) |
                 (whitespace.repeat >> comment >> whitespace.repeat)

    # TOML
    toml = expression.maybe >> (newline.repeat >> expression).repeat

    toml.then_eof
  end
end
