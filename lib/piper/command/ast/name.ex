defmodule Piper.Command.Ast.Name do

  alias Piper.Command.SemanticError
  alias Piper.Command.Ast

  defstruct [bundle: nil, entity: nil]

  def new({:string, meta, value}) do
    if Keyword.get(meta, :hint) == :qualified_name do
      {line, col} = Keyword.fetch!(meta, :position)
      [bundle, entity] = String.split(String.Chars.to_string(value), ":", parts: 2)
      bundle_ast = Ast.String.new({line, col}, bundle)
      entity_ast = Ast.String.new({line, col + (String.length(bundle) + 1)}, entity)
      %__MODULE__{bundle: bundle_ast, entity: entity_ast}
    else
      entity_ast = Ast.String.new({:string, meta, value})
      %__MODULE__{entity: entity_ast}
    end
  end
  def new([bundle: bundle, entity: entity]) do
    %__MODULE__{bundle: Ast.String.new(bundle), entity: Ast.String.new(entity)}
  end

end
