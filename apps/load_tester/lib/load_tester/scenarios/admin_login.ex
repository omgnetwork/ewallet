defmodule LoadTester.Scenarios.AdminLogin do
  @moduledoc """
  Test scenario for `/api/admin/admin.login`.
  """
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/admin.login",
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
    |> update_assign(user_id: fn _ -> result.data.user_id end)
    |> update_assign(user: fn _ -> result.data.user end)
  end
end
