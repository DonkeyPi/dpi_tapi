defmodule Dpi.Tapi.MixProject do
  use Mix.Project

  def project do
    [
      app: :dpi_tapi,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dpi_tui, path: "../dpi_tui"},
      {:dpi_react, path: "../dpi_react"}
    ]
  end
end
