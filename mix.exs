defmodule Caravan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :caravan,
      aliases: [
        test: "test --no-start"
      ],
      version: "1.0.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
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
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test},
      {:xxhash, "~> 0.2.1"},
      {:libcluster, "~> 3.0", optional: true},
      {:recon, "~> 2.3", optional: true},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:local_cluster, "~> 1.0", only: [:test]}
    ]
  end

  defp docs do
    [main: Caravan]
  end


  defp elixirc_paths(:test) do
    [
      "lib",
      "test/support"
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

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
