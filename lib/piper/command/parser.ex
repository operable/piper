defmodule Piper.Command.ParserOptions do

  defstruct [command_resolver: nil,
             max_expansion_depth: 5]

  def defaults() do
    %__MODULE__{}
  end

end

defmodule Piper.Command.Parser do

  alias Piper.Command.ParserOptions

  @moduledoc """
  Elixir interface to :piper_cmd_parser.
  """

  alias Piper.Command.SemanticError

  def scan_and_parse(text), do: scan_and_parse(text, ParserOptions.defaults())
  def scan_and_parse(text, %ParserOptions{}=opts) do
    try do
      :piper_cmd_parser.scan_and_parse(text, opts)
    catch
      error -> SemanticError.format_error(error)
    end
  end

end
