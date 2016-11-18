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
               use_legacy_parser: boolean,
               expansion_limit: pos_integer}

  defstruct [resolver: nil, use_legacy_parser: false,
             expansion_limit: 5]

  def defaults() do
    %__MODULE__{}
  end

end

defmodule Piper.Command.Parser do

  @moduledoc """
  Elixir interface to YECC-based parsers (:piper_cmd_parser, :piper_cmd2_parser)
  """

  alias Piper.Command.SemanticError
  alias Piper.Command.ParserOptions
  alias Piper.Command.ParseContext

  def scan_and_parse(text), do: scan_and_parse(text, ParserOptions.defaults())
  def scan_and_parse(text, %ParserOptions{}=opts) do
    {:ok, context} = ParseContext.start_link(opts)
    if opts.use_legacy_parser do
      old_parse(text, context)
    else
      new_parse(text, context)
    end
  end

  def expand(_alias, text) do
    context = ParseContext.current()
    opts = ParseContext.get_options(context)
    if opts.use_legacy_parser do
      :piper_cmd_parser.scan_and_parse(text)
    else
      :piper_cmd2_parser.parse_pipeline(text)
    end
  end

  def get_options() do
    context = ParseContext.current()
    ParseContext.get_options(context)
  end

  def start_alias(alias) do
    context = ParseContext.current()
    ParseContext.start_alias(context, alias)
  end

  def finish_alias(alias) do
    context = ParseContext.current()
    ParseContext.finish_alias(context, alias)
  end

  def valid_name?(text) do
    cond do
      # Plain text
      Regex.match?(~r/^[a-zA-Z_\-0-9]+$/, text) ->
        true
      # Slack-style emoji
      Regex.match?(~r/^:[a-zA-Z_\-0-9]+:$/, text) ->
        true
      # HipChat-style emoji
      Regex.match?(~r/^\([a-zA-Z_\-0-9]+\)$/, text) ->
        true
      true ->
        false
    end
  end

  # Uses new stacked parsers
  defp new_parse(text, context) do
    try do
      case :piper_cmd2_parser.parse_pipeline(text) do
        {:ok, ast} ->
          {:ok, ast}
        %SemanticError{}=error ->
          SemanticError.format_error(error)
        {:error, reason} when is_binary(reason) ->
          {:error, reason}
      end
    catch
      error ->
        SemanticError.format_error(error)
    after
      Process.delete(:piper_cp_context)
      ParseContext.stop(context)
    end
  end

  defp old_parse(text, context) do
    try do
      :piper_cmd_parser.scan_and_parse(text)
    catch
      error -> SemanticError.format_error(error)
    after
      Process.delete(:piper_cp_context)
      ParseContext.stop(context)
    end
  end

end
