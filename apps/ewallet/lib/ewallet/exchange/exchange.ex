# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  differences of the two tokens and thus can be used directly on tokens with different
  `subunit_to_unit` values.

  Returns `{:ok, rate, pair}` if the exchange pair is found.
  """
  @spec get_rate(from_token :: %Token{}, to_token :: %Token{}) ::
          {:ok, Decimal.t(), %ExchangePair{}} | {:error, atom()}
  def get_rate(from_token, to_token) do
    case ExchangePair.fetch_exchangable_pair(
           from_token,
           to_token,
           preload: [:from_token, :to_token]
         ) do
      {:ok, pair} ->
        rate = Decimal.new(pair.rate)
        subunit_scale = Decimal.div(to_token.subunit_to_unit, from_token.subunit_to_unit)
        {:ok, Decimal.mult(rate, subunit_scale), pair}

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
          from_amount :: non_neg_or_nil() | Decimal.t(),
          from_token :: %Token{},
          to_amount :: non_neg_or_nil() | Decimal.t(),
          to_token :: %Token{}
        ) :: {:ok, Calculation.t()} | {:error, atom()}

  # Converts `from_amount` and `to_amount` to Decimal before operating on them
  def validate(from_amount, from_token, to_amount, to_token) when is_number(from_amount) do
    validate(Decimal.new(from_amount), from_token, to_amount, to_token)
  end

  def validate(from_amount, from_token, to_amount, to_token) when is_number(to_amount) do
    validate(from_amount, from_token, Decimal.new(to_amount), to_token)
  end

  # Same-token: valid if `from_amount` and `to_amount` to be equal, error if not.
  def validate(amount, %{uuid: uuid} = token, amount, %{uuid: uuid}) do
    {:ok, build_result(amount, token, amount, token, Decimal.new(1), nil)}
  end

  def validate(from_amount, %{uuid: uuid}, to_amount, %{uuid: uuid}) do
    {:error, :exchange_invalid_rate,
     "expected the same 'from_amount' and 'to_amount' when given the same token, " <>
       "got #{from_amount} and #{to_amount}"}
  end

  # Cross-token: valid if the amounts match the exchange rate.
  def validate(from_amount, from_token, to_amount, to_token) do
    with {:ok, rate, pair} <- get_rate(from_token, to_token),
         expected_to_amount <- Decimal.mult(from_amount, rate),
         {:ok, expected_to_amount} <- normalize(expected_to_amount),
         true <-
           Decimal.equal?(to_amount, expected_to_amount) ||
             {:error, :exchange_invalid_rate, expected_to_amount} do
      {:ok, build_result(from_amount, from_token, to_amount, to_token, rate, pair)}
    else
      {:error, :exchange_amounts_too_small, expected_to_amount} ->
        {:error, :exchange_amounts_too_small,
         "expected the 'from_amount' and 'to_amount' to be greater than zero, " <>
           "got #{from_amount} and #{expected_to_amount}"}

      {:error, :exchange_invalid_rate, expected_to_amount} ->
        {:error, :exchange_invalid_rate,
         "expected 'from_amount' to be #{from_amount} and 'to_amount' to be #{expected_to_amount}, " <>
           "got #{from_amount} and #{to_amount}"}

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
          from_amount :: non_neg_or_nil() | Decimal.t(),
          from_token :: %Token{},
          fo_amount :: non_neg_or_nil() | Decimal.t(),
          to_token :: %Token{}
        ) :: {:ok, Calculation.t()} | {:error, atom()} | {:error, atom(), String.t()}

  # Returns an :invalid_parameter error if both `from_amount` and `to_amount` are missing
  def calculate(nil, _, nil, _) do
    {:error, :invalid_parameter, "an exchange requires from amount, to amount, or both"}
  end

  # Converts `from_amount` and `to_amount` to Decimal before operating on them
  def calculate(from_amount, from_token, to_amount, to_token) when is_number(from_amount) do
    calculate(Decimal.new(from_amount), from_token, to_amount, to_token)
  end

  def calculate(from_amount, from_token, to_amount, to_token) when is_number(to_amount) do
    calculate(from_amount, from_token, Decimal.new(to_amount), to_token)
  end

  # Same-token: populates `from_amount` into `to_amount`
  def calculate(nil, %{uuid: uuid} = token, to_amount, %{uuid: uuid}) do
    {:ok, build_result(to_amount, token, to_amount, token, Decimal.new(1), nil)}
  end

  # Same-token: populates `to_amount` into `from_amount`
  def calculate(from_amount, %{uuid: uuid} = token, nil, %{uuid: uuid}) do
    {:ok, build_result(from_amount, token, from_amount, token, Decimal.new(1), nil)}
  end

  # Cross-token: calculates for the missing `from_amount`
  def calculate(nil, from_token, to_amount, to_token) do
    with {:ok, rate, pair} <- get_rate(from_token, to_token),
         from_amount <- Decimal.div(to_amount, rate),
         {:ok, from_amount} <- normalize(from_amount) do
      {:ok, build_result(from_amount, from_token, to_amount, to_token, rate, pair)}
    else
      {:error, :exchange_amounts_too_small, from_amount} ->
        {:error, :exchange_amounts_too_small,
         "expected the 'from_amount' and 'to_amount' to be greater than zero, " <>
           "got #{from_amount} and #{to_amount}"}

      error ->
        error
    end
  end

  # Cross-token: calculates for the missing `to_amount`
  def calculate(from_amount, from_token, nil, to_token) do
    with {:ok, rate, pair} <- get_rate(from_token, to_token),
         to_amount <- Decimal.mult(from_amount, rate),
         {:ok, to_amount} <- normalize(to_amount) do
      {:ok, build_result(from_amount, from_token, to_amount, to_token, rate, pair)}
    else
      {:error, :exchange_amounts_too_small, to_amount} ->
        {:error, :exchange_amounts_too_small,
         "expected the 'from_amount' and 'to_amount' to be greater than zero, " <>
           "got #{from_amount} and #{to_amount}"}

      error ->
        error
    end
  end

  # Returns an :invalid_parameter error if both `from_amount` and `to_amount` are provided
  def calculate(_from_amount, _, _to_amount, _) do
    {:error, :invalid_parameter, "unable to calculate if amounts are already provided"}
  end

  # Round the subunit amount to integer. Returns :error if the result is 0 or lower,
  # the exchange amounts should never be 0 or less.
  defp normalize(amount) do
    rounded = Decimal.round(amount, 0)
    zero = Decimal.new(0)

    case greater_than(rounded, zero) do
      true -> {:ok, rounded}
      false -> {:error, :exchange_amounts_too_small, rounded}
    end
  end

  defp greater_than(left, right), do: Decimal.compare(left, right) == Decimal.new(1)

  defp build_result(from_amount, from_token, to_amount, to_token, rate, pair) do
    %Calculation{
      from_amount: Decimal.to_integer(from_amount),
      from_token: from_token,
      to_amount: Decimal.to_integer(to_amount),
      to_token: to_token,
      actual_rate: Decimal.to_float(rate),
      pair: pair,
      calculated_at: NaiveDateTime.utc_now()
    }
  end
end
