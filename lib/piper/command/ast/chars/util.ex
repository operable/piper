defmodule Piper.Command.Ast.Chars.Util do

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [escape: 1]
    end
  end

  def escape(value) when is_list(value) do
    "{{" <> Poison.encode!(value) <> "}}"
  end
  def escape(value) do
    value
  end
end
