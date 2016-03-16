defmodule Piper.Command.ParserOptions do

  @type bundle_ref :: nil | String.t
  @type command_or_alias :: String.t
  @type bundle_name :: String.t
  @type command_name :: String.t
  @type pipeline :: String.t
  @type command_resolver :: ((bundle_ref, command_or_alias) -> {:command, {bundle_name, command_name}} |
                                                               {:command, {bundle_name, command_name, term}} |
                                                               {:pipeline, pipeline} |
                                                               {:ambiguous, [bundle_name]} |
                                                               :not_found)

  @type t :: %__MODULE__{
               resolver: command_resolver,
               expansion_limit: pos_integer}

  defstruct [resolver: nil,
             expansion_limit: 5]

  def defaults() do
    %__MODULE__{}
  end

end

defmodule Piper.Command.Parser do

  @moduledoc """
  Elixir interface to :piper_cmd_parser.
  """

  alias Piper.Command.SemanticError
  alias Piper.Command.ParserOptions
  alias Piper.Command.ParseContext

  def scan_and_parse(text), do: scan_and_parse(text, ParserOptions.defaults())
  def scan_and_parse(text, %ParserOptions{}=opts) do
    {:ok, context} = ParseContext.start_link(opts)
    Process.put(:piper_cp_context, context)
    try do
      :piper_cmd_parser.scan_and_parse(text)
    catch
      error -> SemanticError.format_error(error)
    after
      Process.delete(:piper_cp_context)
      ParseContext.stop(context)
    end
  end

  def expand(_alias, text) do
    :piper_cmd_parser.scan_and_parse(text)
  end

  def get_options() do
    context = Process.get(:piper_cp_context)
    ParseContext.get_options(context)
  end

  def start_alias(alias) do
    context = Process.get(:piper_cp_context)
    ParseContext.start_alias(context, alias)
  end

  def finish_alias(alias) do
    context = Process.get(:piper_cp_context)
    ParseContext.finish_alias(context, alias)
  end

end
