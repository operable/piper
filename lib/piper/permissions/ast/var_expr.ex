defmodule Piper.Permissions.Ast.Var do

  defstruct [:name]

  def new(name) do
    %__MODULE__{name: name}
  end

end
