defprotocol Piper.Executable do

  @spec resolve(Piper.Executable, Piper.Scoped) :: :ok | {:error, atom()}
  def resolve(executable, scope)

  @spec execute(Piper.Executable, Piper.Scoped) :: {:ok, term()} | {:error, atom()}
  def execute(executable, scope)

end
