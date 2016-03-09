defimpl Enumerable, for: [Piper.Command.Ast.Pipeline,
                          Piper.Command.Ast.PipelineStage] do

  alias Piper.Command.Ast

  def count(_) do
    {:error, __MODULE__}
  end

  def member?(_, _) do
    {:error, __MODULE__}
  end

  def reduce(%Ast.Pipeline{}=pipeline, acc, fun) do
    reduce(pipeline.stages, acc, fun)
  end
  def reduce(nil, {:cont, acc}, _fun) do
    {:done, acc}
  end
  def reduce(%Ast.PipelineStage{left: left, right: right}, {:cont, acc}, fun) when left != nil do
    reduce(right, fun.(left, acc), fun)
  end
  def reduce(_, {:halt, acc}, _fun) do
    {:halted, acc}
  end
  def reduce(item, {:suspended, acc}, fun) do
    {:suspended, acc, &reduce(item, &1, fun)}
  end

end
