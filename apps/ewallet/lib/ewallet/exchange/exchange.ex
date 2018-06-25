defmodule EWallet.Exchange do
  @moduledoc """
  Provides exchange functionalities.
  """
  alias EWallet.Exchange.Calculation
  alias EWalletDB.{ExchangePair, Token}

  # The private types for calculation parameters
  @typep non_neg_or_nil() :: non_neg_integer() | nil

  @doc """
  Retrieves the exchange rate of the given token pair, adjusted for the `subunit_to_unit`
  differences of the two tokens.

  Returns `{:ok, rate, pair}` if the exchange pair is found.

  If the returned pair is a reversed pair, the returned `rate` is already inverted.
  """
  @spec get_rate(from_token :: %Token{}, to_token :: %Token{}) ::
          {:ok, float(), ExchangePair.t()} | {:error, atom()}

  def get_rate(from_token, to_token) do
    subunit_scale = to_token.subunit_to_unit / from_token.subunit_to_unit

    case ExchangePair.fetch_exchangable_pair(from_token, to_token) do
      {:ok, pair, :direct} ->
        # Direct pair. Return the rate directly.
        {:ok, pair.rate * subunit_scale, pair}

      {:ok, pair, :reversed} ->
        # Reversed pair. Return the inverted rate.
        {:ok, 1 / pair.rate * subunit_scale, pair}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Validates that the given `from_amount` and `to_amount` matches the exchange pair.

  For same-token transactions, returns `true` if `from_amount` and `to_amount` are equal,
  otherwise returns `false`.

  For cross-token transactions, returns `true` if the amounts match the rate
  of the exchange pair, otherwise returns `false`.
  """
  @spec validate(
          from_amount :: non_neg_or_nil(),
          from_token :: %Token{},
          to_amount :: non_neg_or_nil(),
          to_token :: %Token{}
        ) :: {:ok, Calculation.t()} | {:error, atom()}

  # Same-token: valid if `from_amount` and `to_amount` to be equal, error if not.
  def validate(amount, %{uuid: uuid} = token, amount, %{uuid: uuid}) do
    {:ok, build_result(amount, token, amount, token, 1, nil)}
  end

  def validate(_, %{uuid: uuid}, _, %{uuid: uuid}) do
    {:error, :exchange_invalid_rate}
  end

  # Cross-token: valid if the amounts match the exchange rate.
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
  @spec calculate(
          from_amount :: non_neg_or_nil(),
          from_token :: %Token{},
          fo_amount :: non_neg_or_nil(),
          to_token :: %Token{}
        ) :: {:ok, Calculation.t()} | {:error, atom()} | {:error, atom(), String.t()}

  # Returns an :invalid_parameter error if both `from_amount` and `to_amount` are missing
  def calculate(nil, _, nil, _) do
    {:error, :invalid_parameter, "an exchange requires from amount, to amount, or both"}
  end

  # Same-token: populates `from_amount` into `to_amount`
  def calculate(nil, %{uuid: uuid} = token, to_amount, %{uuid: uuid}) do
    {:ok, build_result(to_amount, token, to_amount, token, 1, nil)}
  end

  # Same-token: populates `to_amount` into `from_amount`
  def calculate(from_amount, %{uuid: uuid} = token, nil, %{uuid: uuid}) do
    {:ok, build_result(from_amount, token, from_amount, token, 1, nil)}
  end

  # Cross-token: calculates for the missing `from_amount`
  def calculate(nil, from_token, to_amount, to_token) do
    case get_rate(from_token, to_token) do
      {:ok, rate, pair} ->
        from_amount = to_amount / rate
        {:ok, build_result(from_amount, from_token, from_amount * rate, to_token, rate, pair)}

      {:error, _} = error ->
        error
    end
  end

  # Cross-token: calculates for the missing `to_amount`
  def calculate(from_amount, from_token, nil, to_token) do
    case get_rate(from_token, to_token) do
      {:ok, rate, pair} ->
        to_amount = from_amount * rate
        {:ok, build_result(from_amount, from_token, to_amount, to_token, rate, pair)}

      {:error, _} = error ->
        error
    end
  end

  # Returns an :invalid_parameter error if both `from_amount` and `to_amount` are provided
  def calculate(_from_amount, _, _to_amount, _) do
    {:error, :invalid_parameter, "unable to calculate if amounts are already provided"}
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
