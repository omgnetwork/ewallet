defmodule LoadTester.Scenarios.AccountCreate do
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
        "name": "Load Test Account " <> random_string(8),
        "description": "A load test account generated on #{date}",
        "parent_id": get_master_account(session).id,
      },
      decode: :json,
      with_result: &store_non_master_account(&1, &2)
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

  defp get_master_account(session) do
    config(session, :master_account)
  end

  defp store_non_master_account(session, result) do
    session
    |> update_assign(non_master_account: fn _ -> result.data end)
  end
end
