defmodule Piper.Util.LexerGenerator do

  defmacro __using__(_) do
    quote do
      defstruct original: nil, text: nil, col: 1, line: 1, tokens: []

      Module.register_attribute(__MODULE__, :tokens, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :token_table, accumulate: false, persist: false)
      import unquote(__MODULE__), only: [token: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro token(name, opts) do
    pattern = Keyword.fetch!(opts, :pattern)
    cleaner = Keyword.get(opts, :post)
    debug = Keyword.get(opts, :debug, false)
    if cleaner == nil do
      quote bind_quoted: [name: name, pattern: pattern, debug: debug] do
        @tokens [{name, [pattern: pattern, debug: debug]}]
      end
    else
      quote do
        @tokens [{unquote(name), [pattern: unquote(pattern), post: &__MODULE__.unquote(cleaner)(&1),
                                  debug: unquote(debug)]}]
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      alias Piper.Util.Token
      @token_table unquote(__MODULE__).compile_table(@tokens)

      def tokenize(text) when is_binary(text) do
        lexer = %__MODULE__{text: text, original: text}
        case scan(lexer) do
          {:ok, lexer} ->
            {:ok, lexer.tokens}
          error ->
            error
        end
      end

      def format_error({:error, {:unexpected_end, col, _lexer}}) do
        "Unexpected end of input at column #{col}"
      end
      def format_error({:error, {:unexpected_input, col, lexer}}) do
        "Unexpected input at column #{col}:\n#{lexer.original}\n#{String.duplicate(" ", col - 1)}^"
      end

      def scan(%__MODULE__{}=lexer) do
        case scan_for_tokens(lexer) do
          {:ok, lexer} ->
            {:ok, lexer}
          {:error, lexer} ->
            which_error(lexer)
        end
      end

      defp which_error(%__MODULE__{text: "", col: col}=lexer) do
        {:error, {:unexpected_end, col, lexer}}
      end
      defp which_error(%__MODULE__{col: col}=lexer) do
        {:error, {:unexpected_input, col, lexer}}
      end

      defp scan_for_tokens(%__MODULE__{text: ""}=lexer) do
        {:ok, %{lexer | tokens: Enum.reverse(lexer.tokens)}}
      end
      defp scan_for_tokens(%__MODULE__{text: text, line: line, col: col, tokens: tokens}=lexer) do
        result = scan_table(text, @token_table, line, col)
        case result do
          {:skip, token_size, text} ->
            scan_for_tokens(%{lexer | text: text, col: col + token_size})
          {:skip_line, _, text} ->
            scan_for_tokens(%{lexer | text: text, col: 1, line: line + 1})
          {token, token_size, text} ->
            scan_for_tokens(%{lexer | text: text, col: col + token_size, tokens: [token|tokens]})
          :nomatch ->
            {:error, lexer}
        end
      end

      defp scan_table(_text, [], _line, _col) do
        :nomatch
      end
      defp scan_table(text, [{type, body}|t], line, col) do
        result = run_entry(text, type, body)
        case result do
          false ->
            scan_table(text, t, line, col)
          {token_text, cleaned_text, token_size, text} ->
            if type == :skip or type == :skip_line do
              {type, token_size, text}
            else
              {make_token(type, line, col, token_text, cleaned_text), token_size, text}
            end
        end
      end

      defp run_entry(_text, _type, []),
      do: false
      defp run_entry(text, type, [body|t]) do
        regex = Keyword.fetch!(body, :pattern)
        debug = Keyword.fetch!(body, :debug)
        cleaner = Keyword.get(body, :post, &(&1))
        result = match_entry(text, regex, cleaner)
        if debug == true do
          IO.puts("(#{type}) Evaluating ~r/#{regex.source}/ against \"#{text}\": #{inspect result}")
        end
        case result do
          nil ->
            run_entry(text, type, t)
          result ->
            result
        end
      end

      defp match_entry(text, regex, cleaner) do
        case Regex.run(regex, text, capture: :first, return: :index) do
          nil ->
            nil
          [{_, index}] ->
            {token_text, text} = String.split_at(text, index)
            case cleaner.(token_text) do
              :error ->
                nil
              result ->
                {token_text, result, index, text}
            end
        end
      end

      defp make_token(:skip, _, _, _),
      do: :skip
      defp make_token(type, line, col, text, text) do
        %Token{type: type, line: line, col: col, text: text}
      end
      defp make_token(type, line, col, text, cleaned) do
        %Token{type: type, line: line, col: col, text: cleaned, raw: text}
      end

    end
  end

  def compile_table(tokens) do
    compile_table(tokens, nil, [], [])
  end

  def compile_table([], _prev, [], table) do
    table
  end
  def compile_table([], prev, token, table) do
    [{prev, Enum.reverse(token)}|table]
  end
  def compile_table([[{type, body}]|t], nil, [], []) do
    compile_table(t, type, [body], [])
  end
  def compile_table([[{type, body}]|t], type, token, table) do
    compile_table(t, type, [body|token], table)
  end
  def compile_table([[{type, body}]|t], prev, token, table) do
    compile_table(t, type, [body], [{prev, token}|table])
  end

end
