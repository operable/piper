defmodule Piper.Permissions.Ast.Var do

  @derive [Poison.Encoder]

  defstruct [{:'$ast$', "var"}, :name]

  def new(name) do
    %__MODULE__{name: name}
  end

end
