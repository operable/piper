defprotocol Piper.Scoped do

  @spec set_parent(Piper.Scoped) :: {:ok, Piper.Scoped} | {:error, :have_parent}
  def set_parent(parent_scope)

  @spec lookup(Piper.Scoped, String.t) :: {:ok, term()} | {:error, :not_found}
  def lookup(scope, name)

  @spec set(Piper.Scoped, String.t, term()) :: {:ok, Piper.Scoped} | {:error, :already_stored}
  def set(scope, name, value)

  @spec bind_variable(Piper.Scoped, Piper.Ast.Variable, term) :: {:ok, Piper.Scoped} | {:error, :already_bound}
  def bind_variable(scope, var, value)

  @spec lookup_variable(Piper.Scoped, Piper.Ast.Variable) :: {:ok, term()} | {:error, :not_found}
  def lookup_variable(scope, var)

end
