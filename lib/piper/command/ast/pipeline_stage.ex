defmodule Piper.Command.Ast.PipelineStage do

  alias Piper.Command.Ast

  defstruct [line: nil, col: nil, left: nil, right: nil, type: nil]

  # left stage's right field is nil so we can set the right stage directly
  def new({type, {line, col}, _}, %Ast.PipelineStage{right: nil}=left, %Ast.PipelineStage{}=right) do
    %{left | type: type, line: line, col: col, right: right}
  end
  # left stage's right field isn't nil so we have to walk the chain
  # of stages (with left stage's right field as the head of the chain)
  # to find the end which is where we'll add the right stage.
  #
  # We can visualize this as a tree traversal followed by an update.
  # The "left" and "right" function args are represented as "L" and "R"
  # in the diagram. "*" represents the end, or bottom, of the tree.
  #
  #                 L
  #                / \
  #               a   b
  #                  / \
  #                 c   d
  #                    / \
  #                   e   *
  #
  # Given L's shape we need to traverse the rightmost children (L->b->d->*) to add R in order
  # to preserve overall tree ordering. This is important as the tree order also represents
  # the pipeline's execution order.
  #
  # Adding R to L results in the following tree:
  #
  #                 L
  #                / \
  #               a   b
  #                  / \
  #                 c   d
  #                    / \
  #                   e   R
  #                      / \
  #                     Ra  Rb
  #                        / \
  #                       Rc  *

  def new({type, {_line, _col}, _}, %Ast.PipelineStage{}=left, %Ast.PipelineStage{}=right) when type in [:pipe, :iff] do
    concatenate(left, right, type)
  end
  def new({type, {line, col}, _}, %Ast.Invocation{}=left, %Ast.PipelineStage{}=right) when type in [:pipe, :iff] do
    %__MODULE__{line: line, col: col, left: left, right: right, type: type}
  end

  def new(%__MODULE__{}=stage) do
    stage
  end
  def new(left) do
    %__MODULE__{line: 0, col: 0, left: left}
  end

  defp concatenate(%Ast.PipelineStage{right: nil}=stage, %Ast.PipelineStage{}=new_stage, type) do
    %{stage | right: new_stage, type: type}
  end
  defp concatenate(%Ast.PipelineStage{right: right}=stage, %Ast.PipelineStage{}=new_stage, type) do
    %{stage | right: concatenate(right, new_stage, type)}
  end

end
