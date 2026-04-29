defmodule Paddle.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/szTheory/oarlock"

  def project do
    [
      app: :paddle,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "oarlock",
      description:
        "Paddle Billing SDK for Elixir — typed structs, pure-function webhooks, " <>
          "Req-based HTTP transport, explicit %Paddle.Client{} passing. No Phoenix or Ecto " <>
          "coupling. Used by Accrue. See https://hexdocs.pm/oarlock and guides/accrue-seam.md.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Paddle.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.17"},
      {:telemetry, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "oarlock",
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/oarlock",
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/accrue-seam.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\//
      ]
    ]
  end
end
