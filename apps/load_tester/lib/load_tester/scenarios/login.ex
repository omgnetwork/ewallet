defmodule LoadTester.Scenarios.Login do
  use Chaperon.Scenario

  def init(session) do
    session
    |> assign(rate: 1, interval: seconds(1), auth_token: nil)
    |> ok()
  end

  def run(session) do
    session
    |> post("/api/admin/admin.login",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json"
      },
      json: %{
        "email" => "unnawut+load@omise.co",
        "password" => "loadtesting"
      },
      decode: :json,
      with_result: &store_auth_token(&1, &2)
    )
  end

  def store_auth_token(session, result) do
    session
    |> update_assign(auth_token: fn _ -> result.data.authentication_token end)
    |> IO.inspect()
  end
end
