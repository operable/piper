defimpl Piper.Permissions.Json, for: Piper.Permissions.Ast.Rule do

  alias Piper.Permissions.Ast

  def from_json!(%Ast.Rule{}=rule, json) do
    cs = Map.fetch!(json, "command_selector")
    ps = Map.fetch!(json, "permission_selector")
    cs = Piper.Permissions.Json.from_json!(cs, cs)
    ps = Piper.Permissions.Json.from_json!(ps, ps)
    command = Map.fetch!(json, "command")
    score = Map.fetch!(json, "score")
    %{rule | command_selector: cs, permission_selector: ps, command: command, score: score}
  end

end

defimpl Piper.Permissions.Json, for: Map do

  alias Piper.Permissions.Ast.Json.Util

  def to_json!(value) do
    Poison.encode!(value)
  end

  def from_json!(value, json) do
    structv = Util.map_to_empty_struct(value)
    Piper.Permissions.Json.from_json!(structv, json)
  end

end
