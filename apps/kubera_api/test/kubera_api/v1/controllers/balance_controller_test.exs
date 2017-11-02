defmodule KuberaAPI.V1.BalanceControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1
  import KuberaDB.Factory
  import Mock
  alias KuberaDB.{Repo, User, MintedToken}
  alias KuberaMQ.Entry
  alias Ecto.Adapters.SQL.Sandbox

  def valid_response do
    %{
      "correlation_id" => "d63071c7-2042-4913-af6f-f3e363521434",
      "id" => "889f0ec8-9038-424c-8e25-1d19290dee9b",
      "inserted_at" => "2017-11-01T06:42:58.004972",
      "metadata" => "{}",
      "object" => "entry",
      "transactions" => [
        %{
          "amount" => 100_000,
          "balance_address" => "dda0b902-0a37-4ecf-bb96-e81e89db3d2b",
          "id" => "688b8e65-248a-48ce-a7c6-ad593f7c56b2",
          "inserted_at" => "2017-11-01T06:42:58.043203",
          "minted_token_symbol" => "OMG",
          "object" => "transaction",
          "type" => "debit"
        },
        %{
          "amount" => 100_000,
          "balance_address" => "5b54d25e-8411-4ea7-ac65-9eeed311a6a2",
          "id" => "f1ba0a6a-fbea-4ede-bf69-8b2d127b92c2",
          "inserted_at" => "2017-11-01T06:42:58.044764",
          "minted_token_symbol" => "OMG",
          "object" => "transaction",
          "type" => "credit"
        }
      ]
   }
  end

  describe "/user.credit_balance" do
    # Tests:
    # Valid data
    # Invalid data
    # Connection error
    # Insufficient funds
    # Same correlation_id
    # string amount
    # integer amount
    # nil metadata
    # minted token not found
    # user not found
    # invalid amount

    test "updates the user balance and returns the updated amount" do
      with_mock Entry,
        [insert: fn _data, callback ->
          callback.({:ok, valid_response()})
        end] do
          {:ok, user} = :user |> params_for() |> User.insert()
          {:ok, minted_token} =
            :minted_token |> params_for() |> MintedToken.insert()

          request_data = %{
            provider_user_id: user.provider_user_id,
            symbol: minted_token.symbol,
            amount: 100_000,
            metadata: %{}
          }

          response = build_conn()
            |> put_req_header("accept", @header_accept)
            |> post("/user.credit_balance", request_data)
            |> json_response(:ok)

          assert response == %{"success" => true}
        end
    end
  end
end
