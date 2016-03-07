defmodule Parser.ParsingCase do

  require Logger

  defmacro __using__(_) do
    quote do
      alias :piper_cmd_lexer, as: Lexer
      alias Piper.Command.Parser
      alias Piper.Command.ParserOptions
      use ExUnit.Case

      import unquote(__MODULE__), only: [types: 1,
                                         text: 1,
                                         ast_string: 1,
                                         matches: 2]
    end
  end

  def types(ttypes) when is_list(ttypes) do
    build_type_matchers(ttypes)
  end
  def types(ttypes) do
    types([ttypes])
  end

  def text(text) when is_binary(text) do
    fn([{_, _, token}]) -> String.Chars.to_string(token) == text end
  end
  def text(texts) when is_list(texts) do
    fn(ents) when is_list(ents) ->
      ent_texts = Enum.map(ents, fn({_, _, token}) -> String.Chars.to_string(token) end)
      result = ent_texts == texts
      if result == false do
        Logger.error "#{inspect ent_texts} didn't match text list #{inspect texts}"
      end
      result
      (_) ->
        {:error, :not_a_list}
    end
  end

  def ast_string(ast_str) do
    fn({:error, _}) ->
      false
      (ent) ->
      if "#{ent}" != ast_str do
        Logger.error("#{ent} didn't match expected #{ast_str}")
        false
      else
        true
      end
    end
  end

  def matches({:ok, ents}, matchers) when is_list(matchers) do
    matches(ents, matchers)
  end
  def matches(_ents, []) do
    true
  end
  def matches(ents, [matcher|t]) do
    case matcher.(ents) do
      true ->
        matches(ents, t)
      false ->
        false
    end
  end
  def matches({:ok, ents}, matcher) do
    matches(ents, matcher)
  end
  def matches([], _) do
    false
  end
  def matches(nil, _) do
    false
  end
  def matches(ents, matcher) do
    matcher.(ents)
  end

  defp build_type_matchers(ttypes) do
    fn(ents) when is_list(ents) ->
      ent_types = Enum.map(ents, &(extract_type(&1)))
      if ttypes != ent_types do
        Logger.error("#{inspect ent_types} didn't match expected #{inspect ttypes}")
        false
      else
        true
      end
      (ent) ->
        ent_types = Enum.map([ent], &(extract_type(&1)))
        if ttypes != ent_types do
          Logger.error("#{inspect ent_types} didn't match expected #{inspect ttypes}")
          false
        else
          true
        end
    end
  end

  defp extract_type({type, _, _}), do: type

end
