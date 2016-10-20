defmodule Piper.Test.BindHelpers do

  alias Piper.Command.Parser
  alias Piper.Command.ParserOptions
  alias Piper.Common.Scope

  defmacro __using__(opts \\ []) do
    use_legacy = Keyword.get(opts, :legacy, false)
    quote do
      import unquote(__MODULE__), only: [link_scopes: 1,
                                         make_scope_chain: 1]

      def parse_and_bind(text) do
        parse_and_bind(text, Scope.empty_scope())
      end

      def parse_and_bind(text, vars) when is_map(vars) do
        scope = Scope.from_map(vars)
        parse_and_bind2(text, scope)
      end

      def parse_and_bind2(text, scope, opts \\ %ParserOptions{}) do
        opts = %{opts | use_legacy_parser: unquote(use_legacy)}
        {:ok, ast} = Parser.scan_and_parse(text, opts)
        case Scope.bind(ast, scope) do
          {:ok, new_ast, _scope} ->
            {:ok, new_ast}
          error ->
            error
        end
      end

    end
  end

  def link_scopes([]) do
    Scope.empty_scope()
  end
  def link_scopes(vars) do
    make_scope_chain(Enum.reverse(vars))
  end

  def make_scope_chain([h]) do
    Scope.from_map(h)
  end
  def make_scope_chain([h|t]) do
    parent = make_scope_chain(t)
    scope = Scope.from_map(h)
    {:ok, scope} = Scope.Scoped.set_parent(scope, parent)
    scope
  end

end
