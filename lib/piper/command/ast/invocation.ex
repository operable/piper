defmodule Piper.Command.Ast.Invocation do

  alias Piper.Command.SemanticError
  alias Piper.Command.Ast
  alias Piper.Command.Parser

  defstruct [name: nil, args: [], redir: nil, meta: nil]

  def new(%Ast.Name{}=name, opts \\ []) do
    args = Keyword.get(opts, :args, [])
    redir = Keyword.get(opts, :redir)
    case resolve_name!(name) do
      {:pipeline, pipeline} ->
        left = pipeline.stages.left
        updated_left = %{left | args: left.args ++ args}
        if redir != nil do
          propagate_redir(%{pipeline.stages | left: updated_left}, redir)
        else
          %{pipeline.stages | left: updated_left}
        end
      {:command, name, meta} ->
        %__MODULE__{name: name, args: args, redir: redir, meta: meta}
    end
  end

  defp resolve_name!(%Ast.Name{bundle: bundle, entity: entity}=name) do
    options = Parser.get_options()
    if options != nil and options.resolver != nil do
      call_resolver!(options, bundle, entity)
    else
      {:command, name, nil}
    end
  end

  defp call_resolver!(options, bundle, entity) do
    bundle_name = if bundle != nil do
      bundle.value
    else
      nil
    end
    entity_name = entity.value
    expansion_status = Parser.start_alias(entity_name)
    try do
      case expansion_status do
        {:error, {:max_depth, offender, max_depth}} ->
          throw SemanticError.new(entity, {:expansion_limit, offender, max_depth})
        {:error, {:alias_cycle, cycle}} ->
          throw SemanticError.new(entity, {:alias_cycle, cycle})
        :ok ->
          case options.resolver.(bundle_name, entity_name) do
            {:command, {resolved_bundle, resolved_command, meta}} ->
              {:command, build_replacement_name(resolved_bundle, resolved_command, entity), meta}
            {:command, {resolved_bundle, resolved_command}} ->
              {:command, build_replacement_name(resolved_bundle, resolved_command, entity), nil}
            {:pipeline, text} when is_binary(text) ->
              {:ok, pipeline} = Parser.expand(entity_name, text)
              {:pipeline, pipeline}
            {:ambiguous, bundles} ->
              throw SemanticError.new(entity, {:ambiguous, bundles})
            :not_found ->
              throw SemanticError.new(entity, :not_found)
          end
      end
    after
      Parser.finish_alias(entity_name)
    end
  end

  defp tokenize(name_part, entity, bundle? \\ true) do
    case :piper_cmd_lexer.tokenize(name_part) do
      {:ok, [{type, _, value}]} ->
        {type, {entity.line, entity.col}, value}
      {:ok, _} ->
        if bundle? do
          throw SemanticError.new(entity, {:bad_bundle, name_part})
        else
          throw SemanticError.new(entity, {:bad_command, name_part})
        end
    end
  end

  defp build_replacement_name(resolved_bundle, resolved_command, entity) do
    bundle_token = tokenize(resolved_bundle, entity)
    command_token = tokenize(resolved_command, entity, false)
    Ast.Name.new([bundle: bundle_token, entity: command_token])
  end

  defp propagate_redir(stage, redir) do
    if stage.right == nil do
      %{stage | left: %{stage.left | redir: redir}}
    else
      %{stage | right: propagate_redir(stage.right, redir)}
    end
  end

end
