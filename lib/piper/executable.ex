defprotocol Piper.Executable do

  @spec resolve(Piper.Executable, Piper.Scoped) :: {:ok, Piper.Scoped} | {:error, atom()}
  def resolve(executable, scope)

  @spec prepare(Piper.Executable, Piper.Scoped) :: {:ok, Piper.Executable, Piper.Scoped} | {:error, atom()}
  def prepare(executable, scope)

end
