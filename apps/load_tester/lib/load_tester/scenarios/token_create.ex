defmodule LoadTester.Scenarios.TokenCreate do
  use Chaperon.Scenario

  def run(session) do
    date = DateTime.to_iso8601(DateTime.utc_now())

    session
    |> post("/api/admin/account.create",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{
        "symbol": "LOAD" <> random_string(4),
        "name": "A load test coin generated on #{date}",
        "description": "desc",
        "subunit_to_unit": 1_000_000_000_000_000_000,
        "amount": 1_000_000 * 1_000_000_000_000_000_000
      },
      decode: :json,
      with_result: &store_token(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
    |> binary_part(0, length)
  end

  defp store_token(session, result) do
    session
    |> update_assign(token: fn _ -> result.data end)
  end
end
