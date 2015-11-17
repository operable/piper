defmodule Parser.ParsingCase do

  require Logger
  alias Piper.Util.Token

  defmacro __using__(_) do
    quote do
      alias Piper.Parser
      alias Piper.Lexer
      alias Piper.Ast
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
    fn([ent]) -> ent.text == text end
  end
  def text(texts) when is_list(texts) do
    fn(ents) when is_list(ents) ->
      ent_texts = Enum.map(ents, &(&1.text))
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
    fn(ent) -> "#{ent}" == ast_str end
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
      (%Token{}=ent) ->
        ent_types = Enum.map([ent], &(extract_type(&1)))
        if ttypes != ent_types do
          Logger.error("#{inspect ent_types} didn't match expected #{inspect ttypes}")
          false
        else
          true
        end
    end
  end

  defp extract_type(%Token{}=token) do
    token.type
  end

end
