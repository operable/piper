defmodule Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  defstruct [stages: nil, redirect_to: nil]

  def new(stages) do
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
        cond do
          default == nil ->
            []
          is_list(default) ->
            default
          true ->
            [default]
        end
      redirect ->
        Enum.map(redirect.targets, &(&1.value))
    end
  end

end

defmodule Piper.Command.Ast.PipelineStage do

  alias Piper.Command.Ast

  defstruct [line: nil, col: nil, left: nil, right: nil, type: nil]

  def new({type, {line, col}, _}, %Ast.PipelineStage{right: nil}=left, %Ast.PipelineStage{}=right) do
    %{left | type: type, line: line, col: col, right: right}
  end
  def new({type, {line, col}, _}, left, right) when type in [:pipe, :iff] do
    %__MODULE__{line: line, col: col, left: left, right: right, type: type}
  end

  def new(%__MODULE__{}=stage) do
    stage
  end
  def new(left) do
    %__MODULE__{line: 0, col: 0, left: left}
  end

end
