defmodule LoadTester.Runner do
  use Chaperon.LoadTest
  alias LoadTester.Scenarios.Login
  alias LoadTester.Scenarios.TokenAll

  def default_config, do: %{
    # base_url: "https://ewallet.staging.omisego.io"
    base_url: "http://localhost:4000"
  }

  def scenarios, do: [
    {{10, [Login, TokenAll]}, %{}}
  ]
end
