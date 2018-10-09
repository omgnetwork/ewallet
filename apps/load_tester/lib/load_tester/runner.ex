defmodule LoadTester.Runner do
  use Chaperon.LoadTest

  def default_config, do: %{
    base_url: "https://ewallet.staging.omisego.io"
    # base_url: "http://localhost:4000"
  }

  def scenarios, do: [
    {{1, LoadTester.Scenarios.Login}, %{}}
  ]
end
