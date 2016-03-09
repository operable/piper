defmodule Piper.Command.Ast.Pipeline do

  defstruct [stages: nil]

  def new(stages) do
    %__MODULE__{stages: stages}
  end

end

defmodule Piper.Command.Ast.PipelineStage do

  defstruct [line: nil, col: nil, left: nil, right: nil, type: nil]

  def new({type, {line, col}, _}, left, right) when type in [:pipe, :iff] do
    %__MODULE__{line: line, col: col, left: left, right: right, type: type}
  end

  def new(left) do
    %__MODULE__{line: 0, col: 0, left: left}
  end

end
