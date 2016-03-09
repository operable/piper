defmodule Piper.Command.Ast.Name do

  alias Piper.Command.Ast

  defstruct [bundle: nil, entity: nil]

  def new(opts) do
    bundle = parse(opts, :bundle)
    entity = parse(opts, :entity)
    %__MODULE__{bundle: bundle, entity: entity}
  end

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
