defmodule LoadTester.Scenarios.UserGetWallets do
  @moduledoc """
  Test scenario for `/api/admin/user.get_wallets`.
  """
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/user.get_wallets",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{
        id: config(session, :user).id
      },
      decode: :json,
      with_result: &store_user_wallets(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp store_user_wallets(session, result) do
    session
    |> update_assign(user_wallets: fn _ -> result.data.data end)
  end
end
