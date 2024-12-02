defmodule UeberauthZapier.MixProject do
  use Mix.Project

  @source_url "https://github.com/DanielMusau/ueberauth_zapier"
  @version "0.1.1"

  def project do
    [
      app: :ueberauth_zapier,
      description: "Ueberauth strategy for Zapier OAuth",
      version: @version,
      elixir: "~> 1.14",
      source_url: @source_url,
      homepage_url: @source_url,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        links: %{
          "GitHub" => @source_url
        },
        licenses: ["MIT"]
      ],
      docs: [
        extras: ["README.md"]
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
      {:ueberauth, "~> 0.10.8"},
      {:oauth2, "~> 2.1"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test]}
    ]
  end
end
