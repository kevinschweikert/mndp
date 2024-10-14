defmodule Mndp.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/kevinschweikert/mndp"

  def project do
    [
      app: :mndp,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package(),
      description: description(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs,
        credo: :test
      }
    ]
  end

  defp extra_applications(:dev),
    do: [
      {:wx, :optional},
      {:runtime_tools, :optional},
      {:observer, :optional}
    ]

  defp extra_applications(_), do: []

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MNDP.Application, []},
      extra_applications: [:logger] ++ extra_applications(Mix.env())
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp description do
    "MikroTik Neighbor Device Discovery"
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves_runtime, "~> 0.13", optional: true, only: [:dev, :test, :prod, :docs]},
      {:credo, "~> 1.7", only: :test, runtime: false},
      {:ex_doc, "~> 0.34", only: :docs, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:vintage_net, "~> 0.13", optional: true},
      {:owl, "~> 0.12.0"}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:iex, :vintage_net, :mix],
      plt_file: {:no_warn, "priv/plts/project.plt"},
      list_unused_filters: true
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
