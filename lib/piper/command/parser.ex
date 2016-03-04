defmodule Piper.Command.Parser do

  alias Piper.Command.SemanticError

  def scan_and_parse(text, opts \\ []) do
    try do
      :piper_cmd_parser.scan_and_parse(text, opts)
    catch
      error -> SemanticError.format_error(error)
    end
  end

end
