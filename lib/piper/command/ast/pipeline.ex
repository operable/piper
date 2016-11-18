defmodule Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  defstruct [stages: nil, redirect_to: nil]

  def new(%Ast.PipelineStage{}=stages) do
    pipeline = %__MODULE__{stages: stages}
    redir = Enum.reduce(pipeline, nil, fn(invocation, _) -> invocation.redir end)
    %{pipeline | redirect_to: redir}
  end

  def to_stream(%__MODULE__{}=pipeline, chunk_size \\ 1) do
    Stream.chunk(pipeline, chunk_size)
  end

  def redirect_targets(pipeline, default \\ nil) do
    case pipeline.redirect_to do
      nil ->
        List.wrap(default)
      redirect ->
        Enum.map(redirect.targets, &(&1.value))
    end
  end

end
