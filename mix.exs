defmodule Piper.Mixfile do
  use Mix.Project

  def project do
    [app: :piper,
     version: "0.16.0",
     elixir: "~> 1.3.1",
     erlc_options: [:debug_info, :warnings_as_errors],
     leex_options: [:warnings_as_errors],
     elixirc_paths: elixirc_paths(Mix.env),
     start_permanent: Mix.env == :prod,
     deps: deps] ++ compile_protocols(Mix.env)
  end

  def application do
    [applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:poison, "~> 2.0"},
     {:uuid, "~> 1.1.3"}]
  end

  defp compile_protocols(:prod), do: [build_embedded: true]
  defp compile_protocols(_), do: []

end
