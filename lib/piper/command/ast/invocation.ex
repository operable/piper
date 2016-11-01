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
    if options == nil or options.resolver == nil do
      {{:command, name, nil}, args}
    else
      possibles = possible_command_names(entity, args)
      case Enum.reduce_while(possibles, :not_found, &(resolve_command!(options, bundle, &1, &2))) do
        :not_found ->
          throw SemanticError.new(entity, :not_found)
        result ->
          result
      end
    end
  end

  defp resolve_command!(options, bundle, {name, args}, acc) do
    case call_resolver!(options, bundle, name, args) do
      :not_found ->
        {:cont, acc}
      result ->
        {:halt, result}
    end
  end

  defp call_resolver!(options, bundle, entity, args) do
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
              throw SemanticError.new(entity, {:ambiguous, bundles})
            :not_found ->
              :not_found
          end
      end
    after
      Parser.finish_alias(entity_name)
    end
  end

  defp validate(name_part, entity, bundle? \\ true) do
    if Parser.valid_name?(name_part) do
      {:string, {entity.line, entity.col}, name_part}
    else
      if bundle? do
        throw SemanticError.new(entity, {:bad_bundle, name_part})
      else
        throw SemanticError.new(entity, {:bad_command, name_part})
      end
    end
  end

  defp build_replacement_name(resolved_bundle, resolved_command, entity) do
    bundle_token = validate(resolved_bundle, entity)
    command_token = validate(resolved_command, entity, false)
    Ast.Name.new([bundle: bundle_token, entity: command_token])
  end

  defp propagate_redir(stage, redir) do
    if stage.right == nil do
      %{stage | left: %{stage.left | redir: redir}}
    else
      %{stage | right: propagate_redir(stage.right, redir)}
    end
  end

  defp bundle_name(nil), do: nil
  defp bundle_name(bundle), do: bundle.value

  defp possible_command_names(name, args, acc \\ [])
  defp possible_command_names(name, [%Ast.String{value: value}|t]=args, acc) do
    acc = [{name, args}|acc]
    if Regex.match?(~r/^[a-zA-Z0-9_-]+$/, value) do
      name = %{name | value: Enum.join([name.value, value], "-")}
      possible_command_names(name, t, acc)
    else
      acc
    end
  end
  defp possible_command_names(name, args, acc) do
    [{name, args}|acc]
  end

end
