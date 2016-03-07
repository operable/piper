defmodule Piper.Command.Ast.Name do

  alias Piper.Command.Ast

  defstruct [bundle: nil, entity: nil]

  def new(opts) do
    bundle = parse(opts, :bundle)
    entity = parse(opts, :entity)
    bundle = lookup_bundle(bundle, entity)
    %__MODULE__{bundle: bundle, entity: entity}
  end

  defp lookup_bundle(nil, entity) do
    options = :piper_cmd_parser.get_options()
    if options != nil do
      if options.command_resolver != nil do
        case options.command_resolver.(entity.value) do
          {:ok, bundle} ->
            Ast.String.new(bundle)
          error ->
            throw %{error | col: entity.col, line: entity.line}
        end
      end
    end
  end
  defp lookup_bundle(bundle, _), do: bundle

  defp parse(opts, key) do
    case Keyword.get(opts, key) do
      nil ->
        nil
      {:string, _, _}=value ->
        Ast.String.new(value)
      {:emoji, _, _}=value ->
        Ast.Emoji.new(value)
    end
  end

end
