defmodule Caravan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :caravan,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:libcluster]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:libcluster, "~> 3.5", optional: true},
      {:recon, "~> 2.5", optional: true},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [main: Caravan]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Chris Brodt"],
      licenses: ["Apache 2.0"],
      source_url: "https://github.com/uberbrodt/caravan",
      links: %{"Github" => "https://github.com/uberbrodt/caravan"}
    ]
  end

  defp description, do: "Tools for running Distributed Elixir with Nomad and Consul"
end
