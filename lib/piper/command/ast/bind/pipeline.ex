defimpl Piper.Command.Bindable, for: Piper.Command.Ast.Pipeline do

  alias Piper.Command.Bindable

  def resolve(pipeline, scope) do
    Bindable.resolve(pipeline.stages, scope)
  end

  def bind(pipeline, scope) do
    case Bindable.bind(pipeline.stages, scope) do
      {:ok, updated_stages, scope} ->
        {:ok, %{pipeline | stages: updated_stages}, scope}
      error ->
        error
    end
  end

end

defimpl Piper.Command.Bindable, for: Piper.Command.Ast.PipelineStage do

  alias Piper.Command.Bindable

  def resolve(stage, scope) do
    case Bindable.resolve(stage.left, scope) do
      {:ok, scope} ->
        if stage.right != nil do
          Bindable.resolve(stage.right, scope)
        else
          {:ok, scope}
        end
      error ->
        error
    end
  end

  def bind(stage, scope) do
    case Bindable.bind(stage.left, scope) do
      {:ok, updated_left, scope} ->
        if stage.right != nil do
          case Bindable.bind(stage.right, scope) do
            {:ok, updated_right, scope} ->
              {:ok, %{stage | left: updated_left, right: updated_right}, scope}
            error ->
              error
          end
        else
          {:ok, %{stage | left: updated_left}, scope}
        end
      error ->
        error
    end
  end

end
