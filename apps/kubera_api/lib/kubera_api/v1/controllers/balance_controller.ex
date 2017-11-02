defmodule KuberaAPI.V1.BalanceController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias Kubera.Transaction

  def credit(conn, %{"provider_user_id" => _, "symbol" => _, "amount" => amount,
                     "metadata" => _} = attrs) when is_integer(amount) do
    data = Transaction.init(attrs)

    Transaction.create(data, fn response ->
      # To do: Handle errors
      # invalid data
      # insufficient funds
      # To do: Send back the updated balance
      case response do
        {:ok, _data} ->
          # To do: Query balance
          # To do: Serialize balance
          json conn, %{success: true}
        {:error, code, description} ->
          handle_error(conn, code, description)
      end
    end)

    # We might need this to prevent warning from Phoenix.
    # json conn, %{success: true}
  end

  def credit(conn, _params) do
    handle_error(conn, :invalid_parameter)
  end
end
