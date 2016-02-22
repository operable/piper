defmodule Piper.Mixfile do
  use Mix.Project

  def project do
    [app: :piper,
     version: "0.2",
     elixir: "~> 1.2",
     erlc_paths: ["lib/piper/permissions"],
     erlc_options: [:debug_info, :warnings_as_errors],
     leex_options: [:warnings_as_errors],
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [{:poison, "~> 1.5.2"}]
  end

end
