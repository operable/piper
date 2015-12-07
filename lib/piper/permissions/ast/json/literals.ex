defimpl Piper.Permissions.Json, for: [Piper.Permissions.Ast.String,
                          Piper.Permissions.Ast.Integer,
                          Piper.Permissions.Ast.Float,
                          Piper.Permissions.Ast.Bool,
                          Piper.Permissions.Ast.Regex,
                          Piper.Permissions.Ast.Arg,
                          Piper.Permissions.Ast.Option,
                          Piper.Permissions.Ast.List,
                          Piper.Permissions.Ast.Var] do

  alias Piper.Permissions.Ast
  alias Piper.Permissions.Ast.Json.Util

  def from_json!(%Ast.String{}=svalue, %{"line" => line,
                                        "col" => col,
                                        "value" => value,
                                        "quotes" => quotes}) do
    %{svalue | line: line, col: col, value: value, quotes: quotes}
  end

  def from_json!(%Ast.Regex{}=svalue, %{"line" => line,
                                      "col" => col,
                                      "value" => value}) do
    %{svalue | line: line, col: col, value: Regex.compile!(value)}
  end

  def from_json!(%Ast.Arg{}=svalue, %{"line" => line,
                                     "col" => col,
                                     "index" => index}) do
    %{svalue | line: line, col: col, index: parse_index(index)}
  end

  def from_json!(%Ast.Option{}=svalue, %{"line" => line,
                                         "col" => col,
                                         "name" => name}) do
    %{svalue | line: line, col: col, name: parse_index(name)}

  end

  def from_json!(%Ast.List{}=svalue, %{"line" => line,
                                      "col" => col,
                                      "values" => values}) do
    values = for value <- values do
      Piper.Permissions.Json.from_json!(Util.map_to_empty_struct(value), value)
    end
    %{svalue | line: line, col: col, values: values}
  end

  def from_json!(%Ast.Var{}=svalue, %{"name" => name}) do
    %{svalue | name: name}
  end

  def from_json!(svalue, %{"line" => line,
                          "col" => col,
                          "value" => value}) do
    %{svalue | line: line, col: col, value: value}
  end



  defp parse_index("any"), do: :any
  defp parse_index("all"), do: :all
  defp parse_index(x), do: x

end

defimpl Poison.Encoder, for: Piper.Permissions.Ast.Regex do

  alias Piper.Permissions.Ast

  def encode(%Ast.Regex{line: line, col: col, value: value, "$ast$": ast_type}, _) do
    Poison.encode!(%{"$ast$" => ast_type,
                     "line" => line,
                     "col" => col,
                     "value" => value.source})
  end

end
