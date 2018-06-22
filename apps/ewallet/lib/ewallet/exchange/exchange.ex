defmodule EWallet.Exchange do
  @moduledoc """
  Provides exchange functionalities.
  """
  alias EWallet.Exchange.Calculation
  alias EWalletDB.{ExchangePair, Token}

  # The private types for calculation parameters
  @typep non_neg_or_nil() :: non_neg_integer() | nil

  @doc """
  Retrieves the exchange rate of the given token pair.

  Returns `{:ok, rate, pair}` if the exchange pair is found.

  If the returned pair is a reversed pair, the returned `rate` is already inverted.
  """
  def get_rate(from_token, to_token) do
    case ExchangePair.fetch_exchangable_pair(from_token, to_token) do
      {:ok, pair, :direct} ->
        # Direct pair. Return the rate directly.
        {:ok, pair.rate, pair}

      {:ok, pair, :reversed} ->
        # Reversed pair. Return the inverted rate.
        {:ok, 1 / pair.rate, pair}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Validates that the given `from_amount` and `to_amount` matches the exchange pair.

  For same-token transactions, it returns `true` if `from_amount` and `to_amount` are equal,
  otherwise returns `false`.

  For cross-token transactions, it returns `true` if the amounts match the rate
  of the exchange pair, otherwise returns `false`.
  """
  @spec validate(non_neg_or_nil(), %Token{}, non_neg_or_nil(), %Token{}) ::
          {:ok, Calculation.t()} | {:error, atom()}

  # Same-token: valid if `from_amount` and `to_amount` to be equal
  def validate(from_amount, %{uuid: from_token} = token, to_amount, %{uuid: to_token})
      when from_token == to_token do
    case from_amount == to_amount do
      true ->
        {:ok, build_result(from_amount, token, to_amount, token, 1, nil)}

      false ->
        {:error, :exchange_invalid_rate}
    end
  end

  # Cross-token: valid if amounts match the exchange rate
  def validate(from_amount, from_token, to_amount, to_token) do
    case get_rate(from_token, to_token) do
      {:ok, rate, pair} ->
        if to_amount == from_amount * rate do
          {:ok, build_result(from_amount, from_token, to_amount, to_token, rate, pair)}
        else
          {:error, :exchange_invalid_rate}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Calculate the exchange transaction.

  If `from_amount` is nil, the `from_amount` will be calculated from the given inputs.
  If `to_amount` is nil, the `to_amount` will be calculated from the given inputs.

  If both `from_amount` and `to_amount` are nil, `{:error, :invalid_parameter, description}`
  will be returned.
  If both `from_amount` and `to_amount` are given, `{:error, :invalid_parameter, description}`
  error is returned.
  """
  @spec calculate(non_neg_or_nil(), %Token{}, non_neg_or_nil(), %Token{}) ::
          {:ok, Calculation.t()} | {:error, atom()} | {:error, atom(), String.t()}
  # Returns an :invalid_parameter error if both `from_amount` and `to_amount` are missing
  def calculate(nil, _, nil, _) do
    {:error, :invalid_parameter, "an exchange requires from amount, to amount, or both"}
  end

  # Returns an :invalid_parameter error if both `from_amount` and `to_amount` are provided
  def calculate(from_amount, _, to_amount, _) when from_amount != nil and to_amount != nil do
    {:error, :invalid_parameter, "unable to calculate if amounts are already provided"}
  end

  # Calculate same-token transactions
  def calculate(from_amount, %{uuid: from_token} = token, to_amount, %{uuid: to_token})
      when from_token == to_token do
    cond do
      is_nil(from_amount) ->
        {:ok, build_result(to_amount, token, to_amount, token, 1, nil)}

      is_nil(to_amount) ->
        {:ok, build_result(from_amount, token, from_amount, token, 1, nil)}

      true ->
        {:error, :invalid_parameter, "unable to calculate if amounts are already provided"}
    end
  end

  # Calculate cross-token transactions
  def calculate(from_amount, from_token, to_amount, to_token) do
    calculate_cross_token(from_amount, from_token, to_amount, to_token)
  end

  # Cross-token: calculates for the missing `from_amount`
  defp calculate_cross_token(nil, from_token, to_amount, to_token) do
    case get_rate(from_token, to_token) do
      {:ok, rate, pair} ->
        from_amount = to_amount / rate
        {:ok, build_result(from_amount, from_token, from_amount * rate, to_token, rate, pair)}

      {:error, _} = error ->
        error
    end
  end

  # Cross-token: calculates for the missing `to_amount`
  defp calculate_cross_token(from_amount, from_token, nil, to_token) do
    case get_rate(from_token, to_token) do
      {:ok, rate, pair} ->
        to_amount = from_amount * rate
        {:ok, build_result(from_amount, from_token, to_amount, to_token, rate, pair)}

      {:error, _} = error ->
        error
    end
  end

  defp build_result(from_amount, from_token, to_amount, to_token, rate, pair) do
    %Calculation{
      from_amount: from_amount,
      from_token: from_token,
      to_amount: to_amount,
      to_token: to_token,
      actual_rate: rate,
      pair: pair,
      calculated_at: NaiveDateTime.utc_now()
    }
  end
end
