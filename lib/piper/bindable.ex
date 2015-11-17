defprotocol Piper.Bindable do

  @spec resolve(Piper.Bindable, Piper.Scoped) :: {:ok, Piper.Scoped} | {:error, atom()}
  def resolve(executable, scope)

  @spec bind(Piper.Bindable, Piper.Scoped) :: {:ok, Piper.Bindable, Piper.Scoped} | {:error, atom()}
  def bind(executable, scope)

end
