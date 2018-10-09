defmodule LoadTester.Scenarios.TransactionCreate do
  use Chaperon.Scenario

  def init(session) do
    session
    |> assign(rate: 1, interval: seconds(5))
    |> ok()
  end

  def run(session) do
    from_account = config(session, :master_account)
    to_user = config(session, :user)
    token = Map.get(config(session, :tokens), "OMG")

    session
    |> post("/api/admin/transaction.create",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{
        idempotency_token: :rand.uniform(9999999) |> to_string(),
        from_account_id: from_account.id,
        to_user_id: to_user.id,
        token_id: token.id,
        amount: :rand.uniform() * token.subunit_to_unit |> round(),
        metadata: %{}
      }
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end
end
