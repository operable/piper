defmodule Piper.Mixfile do
  use Mix.Project

  def project do
    [app: :piper,
     version: "0.6.0",
     elixir: "~> 1.2",
     elixirc_options: allow_warnings([]),
     erlc_paths: ["lib/piper/permissions", "lib/piper/command"],
     erlc_options: allow_warnings([:debug_info]),
     leex_options: allow_warnings([]),
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp allow_warnings(opts) do
    if Keyword.keyword?(opts) do
      [{:warnings_as_errors, not(warnings_allowed?)}|opts]
    else
      if warnings_allowed? do
        opts
      else
        [:warnings_as_errors|opts]
      end
    end
  end

  defp warnings_allowed?() do
    System.get_env("ALLOW_WARNINGS") != nil
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:poison, "~> 1.5.2"},
     {:uuid, "~> 1.1.3"}]
  end

end
