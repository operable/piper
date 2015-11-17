defmodule Piper.Util.TokenWrapper do

  alias Piper.Util.Token

  defmacro __using__(_) do
    quote do
      import Piper.Util.TokenWrapper, only: [defwrapper: 1]
      alias Piper.Util.Token
    end
  end

  defmacro defwrapper(fields) do
    build_wrapper_decl(fields)
  end

  defp build_wrapper_decl(fields) do
    {token_type, converter, struct_fields, value_field} = parse_fields(fields)
    codegen(token_type, converter, struct_fields, value_field)
  end

  defp codegen(token_type, nil, struct_fields, value_field) do
    quote location: :keep do
      defstruct unquote(struct_fields)

      def new(%Token{type: toktype}=token) when toktype in unquote(token_type) do
        node = %__MODULE__{line: token.line, col: token.col}
        Map.put(node, unquote(value_field), token.text)
      end
    end
  end
  defp codegen(token_type, converter, struct_fields, value_field) do
    quote location: :keep do
      defstruct unquote(struct_fields)

      def new(%Token{type: toktype}=token) when toktype in unquote(token_type) do
        node = %__MODULE__{line: token.line, col: token.col}
        node = Map.put(node, unquote(value_field), token.text)
        __MODULE__.unquote(converter)(node)
      end
    end
  end

  defp parse_fields(fields) do
    {converter, fields} = extract_converter(fields)
    token_type = ensure_list(Keyword.fetch!(fields, :token_type))
    value_field = Keyword.fetch!(fields, :value)
    fields = Keyword.get(fields, :others, [])
    fields = [{:line, nil}, {:col, nil}, value_field] ++ fields
    fields = for field <- fields do
      case field do
        {_, _} ->
          field
        _ ->
          {field, nil}
      end
    end
    {token_type, converter, fields, value_field}
  end

  defp extract_converter(fields) do
    remaining = Keyword.take(fields, [:value, :others, :token_type])
    case Keyword.get(fields, :converter) do
      nil ->
        {nil, remaining}
      name when is_atom(name) ->
        {name, remaining}
    end
  end

  defp ensure_list(items) when is_list(items) do
    items
  end
  defp ensure_list(item) do
    [item]
  end

end
