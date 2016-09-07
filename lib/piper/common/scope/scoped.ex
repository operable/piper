defprotocol Piper.Common.Scope.Scoped do

  @spec set_parent(Piper.Common.Scope.Scoped, Piper.Common.Scope.Scoped) :: {:ok, Piper.Common.Scope.Scoped} | {:error, :have_parent}
  def set_parent(scope, parent_scope)

  @spec lookup(Piper.Common.Scope.Scoped, String.t) :: {:ok, term()} | {:error, :not_found}
  def lookup(scope, name)

  @spec set(Piper.Common.Scope.Scoped, String.t, term()) :: {:ok, Piper.Common.Scope.Scoped} | {:error, :already_stored}
  def set(scope, name, value)

  @spec erase(Piper.Common.Scope.Scoped, String.t) :: Piper.Common.Scope.Scoped
  def erase(scope, name)

  @spec update(Piper.Common.Scope.Scoped, String.t, term()) :: {:ok, Piper.Common.Scope.Scoped} | {:error, :not_found}
  def update(scope, name, value)

  @spec bind_variable(Piper.Common.Scope.Scoped, Piper.Common.Ast.Variable, term) :: {:ok, Piper.Common.Scope.Scoped} | {:error, :already_bound}
  def bind_variable(scope, var, value)

  @spec lookup_variable(Piper.Common.Scope.Scoped, Piper.Common.Ast.Variable) :: {:ok, term()} | {:error, :not_found}
  def lookup_variable(scope, var)

end
