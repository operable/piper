defmodule Piper.Command.Ast.Pipeline do

  alias Piper.Command.Ast

  defstruct [stages: nil]

  def new(%Ast.PipelineStage{}=stages) do
    %__MODULE__{stages: stages}
  end

  def to_stream(%__MODULE__{}=pipeline, chunk_size \\ 1) do
    Stream.chunk(pipeline, chunk_size)
  end

  def redirect(%__MODULE__{}=pipeline) do
    traverse(pipeline.stages, &get_redirects/1)
  end

  def raw_redirect_targets(%__MODULE__{}=pipeline) do
    redirect = redirect(pipeline)
    if redirect != nil do
      Enum.map(redirect.targets, &("#{&1}"))
    else
      nil
    end
  end

  defp traverse(%Ast.PipelineStage{right: right}=stage, tf) do
    case tf.(stage) do
      {:halt, value} ->
        value
      :cont ->
        if right == nil do
          nil
        else
          traverse(right, tf)
        end
    end
  end

  defp get_redirects(%Ast.PipelineStage{left: left, right: nil}) do
    {:halt, left.redir}
  end
  defp get_redirects(_), do: :cont

end
