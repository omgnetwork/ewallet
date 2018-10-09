defmodule LoadTester.Scenarios.TokenAll do
  use Chaperon.Scenario

  def init(session) do
    session
    |> assign(rate: 1, interval: seconds(1))
    |> ok()
  end

  def run(session) do
    session
    |> post("/api/admin/token.all", json: %{"search_terms" => "OMG"})
  end
end
