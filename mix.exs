defmodule Mndp.MixProject do
  use Mix.Project

  @version "0.1.0"
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MNDP.Application, []},
      extra_applications: [
        :logger,
        {:inets, :optional},
        {:wx, :optional},
        {:runtime_tools, :optional},
        {:observer, :optional}
      ]
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
        # "CHANGELOG.md"
      ],
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
      {:vintage_net, "~> 0.7", optional: true, runtime: false}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:iex, :vintage_net, :inets]
    ]
  end

  defp docs do
    [
      # "CHANGELOG.md"],
      extras: ["README.md"],
      main: "readme"
      # Don't include source refs since lines numbers don't match up to files
      # source_ref: "v#{@version}",
      # source_url: @source_url
    ]
  end
end
