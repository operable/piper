defprotocol Piper.Command.Bindable do

  @spec resolve(Piper.Command.Bindable, Piper.Command.Scoped) :: {:ok, Piper.Command.Scoped} | {:error, term()}
  def resolve(executable, scope)

  @spec bind(Piper.Command.Bindable, Piper.Command.Scoped) :: {:ok, Piper.Command.Bindable, Piper.Command.Scoped} | {:error, term()}
  def bind(executable, scope)

end
