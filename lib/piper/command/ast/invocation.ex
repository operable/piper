defmodule Piper.Command.Ast.Invocation do

  alias Piper.Command.SemanticError
  alias Piper.Command.Ast

  defstruct [name: nil, args: [], redir: nil, meta: nil]

  def new(%Ast.Name{}=name, opts \\ []) do
    {name, meta} = resolve_name!(name)
    args = Keyword.get(opts, :args, [])
    redir = Keyword.get(opts, :redir)
    %__MODULE__{name: name, args: args, redir: redir, meta: meta}
  end

  defp resolve_name!(%Ast.Name{bundle: bundle, entity: entity}=name) do
    options = :piper_cmd_parser.get_options()
    if options != nil and options.resolver != nil do
      call_resolver!(options, bundle, entity)
    else
      {name, nil}
    end
  end

  defp call_resolver!(options, bundle, entity) do
    bundle_name = if bundle != nil do
      bundle.value
    else
      nil
    end
    entity_name = entity.value
    case options.resolver.(bundle_name, entity_name) do
      {:command, {resolved_bundle, resolved_command, meta}} ->
        {build_replacement_name(resolved_bundle, resolved_command, entity), meta}
      {:command, {resolved_bundle, resolved_command}} ->
        {build_replacement_name(resolved_bundle, resolved_command, entity), nil}
      {:ambiguous, bundles} ->
        throw SemanticError.new(entity, {:ambiguous, bundles})
      :not_found ->
        throw SemanticError.new(entity, :not_found)
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

end
