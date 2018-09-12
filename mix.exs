defmodule Blunder.Mixfile do
  use Mix.Project

  def project do
    [
      app: :blunder,
      name: "Blunder",
      version: "1.0.4",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: repo_url(),
      docs: docs(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test, "ci": :test],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.18", only: :dev},
      {:excoveralls, "~> 0.8", only: :test},
      {:wormhole, "~> 2.1"},
    ]
  end

  def docs do
    [
      main: "readme",
      source_url: repo_url(),
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: [
        "Trevor Little"
      ],
      links: %{"Github" => repo_url()},
      organization: "decisiv",
    ]
  end

  def aliases do
    [
      ci: [
        "coveralls --raise",
        "credo --strict",
      ]
    ]
  end

  defp description do
    """
    Package for simplifying error representation and handling in an Absinthe application
    """
  end

  defp repo_url, do: "https://github.decisiv.net/PlatformServices/blunder"

end
