defmodule LoadTester.Scenarios.TransactionCreate do
  use Chaperon.Scenario

  @num_requests 30 * 10
  @duration seconds(10)

  def init(session) do
    session
    |> assign(rate: @num_requests, interval: @duration)
    |> ok()
  end

  def run(session) do
    session
    |> cc_spread(
      :do_run,
      session.assigned.rate,
      session.assigned.interval
    )
  end

  def do_run(session) do
    from_account = get_master_account(session)
    to_account = get_non_master_account(session)
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
        to_account_id: to_account.id,
        token_id: token.id,
        amount: :rand.uniform() * token.subunit_to_unit |> round(),
        metadata: %{}
      }
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp get_master_account(session) do
    config(session, :master_account)
  end

  defp get_non_master_account(session) do
    config(session, :non_master_account)
  end
end
