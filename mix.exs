defmodule Piper.Mixfile do
  use Mix.Project

  def project do
    [app: :piper,
     version: "0.16.2",
     elixir: "~> 1.3.1",
     erlc_options: [:debug_info] ++ warnings_as_errors(:erl),
     leex_options: warnings_as_errors(:erl),
     elixirc_options: warnings_as_errors(:ex),
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
     {:uuid, "~> 1.1.5"}]
  end

  defp compile_protocols(:prod), do: [build_embedded: true]
  defp compile_protocols(_), do: []

  defp warnings_as_errors(type) do
    case System.get_env("ALLOW_WARNINGS") do
      nil ->
        case type do
          :ex ->
            [{:warnings_as_errors, true}]
          :erl ->
            [:warnings_as_errors]
        end
      _ ->
        case type do
          :ex ->
            [{:warnings_as_errors, false}]
          :erl ->
            []
        end
    end
  end

end
