defmodule AdminAPI.V1.TransactionCalculationController do
  @moduledoc """
  The controller to serve transaction calculations.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Exchange
  alias EWalletDB.Token

  @doc """
  Calculates transaction amounts.
  """
  def calculate(conn, attrs) do
    from_amount = attrs["from_amount"]
    from_token = Token.get(attrs["from_token_id"])
    to_amount = attrs["to_amount"]
    to_token = Token.get(attrs["to_token_id"])

    case do_calculate(from_amount, from_token, to_amount, to_token) do
      {:ok, calculation} ->
        render(conn, :calculation, %{calculation: calculation})

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  defp do_calculate(from_amount, from_token_id, to_amount, to_token_id)

  defp do_calculate(nil, _, nil, _) do
    {:error, :invalid_parameter, "either `from_amount` or `to_amount` is required"}
  end

  defp do_calculate(_, nil, _, nil) do
    {:error, :invalid_parameter, "both `from_token_id` and `to_token_id` are required"}
  end

  defp do_calculate(_, nil, _, _) do
    {:error, :invalid_parameter, "`from_token_id` is required"}
  end

  defp do_calculate(_, _, _, nil) do
    {:error, :invalid_parameter, "`to_token_id` is required"}
  end

  defp do_calculate(nil, from_token, to_amount, to_token) do
    Exchange.calculate(nil, from_token, to_amount, to_token)
  end

  defp do_calculate(from_amount, from_token, nil, to_token) do
    Exchange.calculate(from_amount, from_token, nil, to_token)
  end

  defp do_calculate(from_amount, from_token, to_amount, to_token) do
    Exchange.validate(from_amount, from_token, to_amount, to_token)
  end
end
