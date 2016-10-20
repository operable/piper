defmodule Piper.Command.Ast.InterpolatedString do

  alias Piper.Command.Ast

  defstruct [:exprs, :bound, :quote_type]

  def new([%Ast.String{}=str]), do: str
  def new(exprs) when is_list(exprs) do
    %__MODULE__{exprs: exprs, bound: false}
  end

end
