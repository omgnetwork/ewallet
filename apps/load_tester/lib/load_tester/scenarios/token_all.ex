defmodule LoadTester.Scenarios.TokenAll do
  @moduledoc """
  Test scenario for `/api/admin/token.all`.
  """
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/token.all",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{},
      decode: :json,
      with_result: &store_tokens(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp store_tokens(session, result) do
    session
    |> update_assign(tokens: fn _ -> tokens_to_map(result.data.data) end)
  end

  defp tokens_to_map(data) do
    Enum.reduce(data, %{}, fn token, acc ->
      Map.put(acc, token.symbol, token)
    end)
  end
end
