defmodule LoadTester.Scenarios.AccountAll do
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/account.all",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{},
      decode: :json,
      with_result: &store_accounts(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp store_accounts(session, result) do
    session
    |> update_assign(accounts: fn _ -> accounts_to_map(result.data.data) end)
    |> update_assign(master_account: fn _ -> get_master_account(result.data.data) end)
  end

  defp accounts_to_map(data) do
    Enum.reduce(data, %{}, fn account, acc ->
      Map.put(acc, account.name, account)
    end)
  end

  defp get_master_account(data) do
    Enum.find(data, fn account -> account.master end)
  end
end
