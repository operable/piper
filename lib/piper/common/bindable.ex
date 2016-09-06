defprotocol Piper.Common.Bindable do

  @spec resolve(Piper.Common.Bindable, Piper.Common.Scope.Scoped) :: {:ok, Piper.Common.Scope.Scoped} | {:error, term()}
  def resolve(executable, scope)

  @spec bind(Piper.Common.Bindable, Piper.Common.Scope.Scoped) :: {:ok, Piper.Common.Bindable, Piper.Common.Scope.Scoped} | {:error, term()}
  def bind(executable, scope)

end
