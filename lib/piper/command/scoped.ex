defprotocol Piper.Command.Scoped do

  @spec set_parent(Piper.Command.Scoped, Piper.Command.Scoped) :: {:ok, Piper.Command.Scoped} | {:error, :have_parent}
  def set_parent(scope, parent_scope)

  @spec lookup(Piper.Command.Scoped, String.t) :: {:ok, term()} | {:error, :not_found}
  def lookup(scope, name)

  @spec set(Piper.Command.Scoped, String.t, term()) :: {:ok, Piper.Command.Scoped} | {:error, :already_stored}
  def set(scope, name, value)

  @spec bind_variable(Piper.Command.Scoped, Piper.Command.Ast.Variable, term) :: {:ok, Piper.Command.Scoped} | {:error, :already_bound}
  def bind_variable(scope, var, value)

  @spec lookup_variable(Piper.Command.Scoped, Piper.Command.Ast.Variable) :: {:ok, term()} | {:error, :not_found}
  def lookup_variable(scope, var)

end
