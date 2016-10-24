defmodule Piper.Command.Ast.Invocation do

  alias Piper.Command.SemanticError
  alias Piper.Command.Ast
  alias Piper.Command.Parser

  defstruct [id: nil, name: nil, args: [], redir: nil, meta: nil]

  def new(%Ast.Name{}=name, opts \\ []) do
    args = Keyword.get(opts, :args, [])
    redir = Keyword.get(opts, :redir)
    case resolve_name!(name, args) do
      {{:pipeline, pipeline}, args} ->
        left = pipeline.stages.left
        updated_left = %{left | args: left.args ++ args}
        if redir != nil do
          propagate_redir(%{pipeline.stages | left: updated_left}, redir)
        else
          %{pipeline.stages | left: updated_left}
        end
      {{:command, name, meta}, args} ->
        %__MODULE__{id: UUID.uuid4, name: name, args: args, redir: redir, meta: meta}
    end
  end

  defp resolve_name!(%Ast.Name{bundle: bundle, entity: entity}=name, args) do
    options = Parser.get_options()
    if options != nil and options.resolver != nil do
      call_resolver!(options, bundle, entity, args)
    else
      {{:command, name, nil}, args}
    end
  end

  defp call_resolver!(options, bundle, entity, args, referenced_entity \\ nil) do
    referenced_entity = referenced_entity(referenced_entity, entity)
    bundle_name = bundle_name(bundle)
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
              {{:command, build_replacement_name(resolved_bundle, resolved_command, entity), meta}, args}
            {:command, {resolved_bundle, resolved_command}} ->
              {{:command, build_replacement_name(resolved_bundle, resolved_command, entity), nil}, args}
            {:pipeline, text} when is_binary(text) ->
              {:ok, pipeline} = Parser.expand(entity_name, text)
              {{:pipeline, pipeline}, args}
            {:ambiguous, bundles} ->
              throw SemanticError.new(referenced_entity, {:ambiguous, bundles})
            :not_found ->
              case args do
                [%Ast.String{value: value}|t] ->
                  call_resolver!(options, bundle, %{entity | value: Enum.join([entity.value, value], "-")}, t, referenced_entity)
                _ ->
                  throw SemanticError.new(referenced_entity, :not_found)
              end
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

  defp referenced_entity(nil, entity), do: entity
  defp referenced_entity(ref_entity, _), do: ref_entity

  defp bundle_name(nil), do: nil
  defp bundle_name(bundle), do: bundle.value

end
