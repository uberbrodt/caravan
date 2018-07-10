defmodule Caravan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :caravan,
      version: "1.0.0-rc.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps()
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
      {:libcluster, "~> 3.0", optional: true},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:recon, "~> 2.3", optional: true}
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

  defp description, do: "Tools for running Distributed Elixir with Nomad and
  Consul"
end
