defmodule EWallet.Exchange.Calculator do
  alias EWallet.Exchange.Calculation
  alias EWalletDB.ExchangePair

  # The private types for calculation parameters
  @typep non_neg_or_nil() :: non_neg_integer() | nil

  @doc """
  Calculate the exchange transaction.

  If given a nil `from_amount`, the `from_amount` will be calculated from the given inputs.
  If given a nil `to_amount`, the `to_amount` will be calculated from the given inputs.

  If given a nil to both `from_amount` and `to_amount`, an error tuple will be returned.
  If given the same `from_token` and `to_token`, an error tuple will be returned.

  If given both `from_amount` and `to_amount`, but the amounts do not match the existing rate,
  an error tuple will be returned.
  """
  @spec calculate(non_neg_or_nil(), %EWalletDB.Token{}, non_neg_or_nil(), %EWalletDB.Token{}) ::
          {:ok, Calculation.t()} | {:error, atom()} | {:error, atom(), String.t()}
  def calculate(nil, _, nil, _) do
    {:error, :invalid_parameter, "either `from_amount` or `to_amount` or both must be provided"}
  end

  def calculate(_, %{uuid: from_uuid}, _, %{uuid: to_uuid}) when from_uuid == to_uuid do
    {:error, :invalid_parameter, "`from_token` and `to_token` must be different tokens"}
  end

  def calculate(nil, from_token, to_amount, to_token) do
    if_pair_found(from_token, to_token, fn pair, actual_rate ->
      {:ok,
       %Calculation{
         from_amount: to_amount / actual_rate,
         from_token: from_token,
         to_amount: to_amount,
         to_token: to_token,
         actual_rate: actual_rate,
         pair: pair,
         calculated_at: NaiveDateTime.utc_now()
       }}
    end)
  end

  def calculate(from_amount, from_token, nil, to_token) do
    if_pair_found(from_token, to_token, fn pair, actual_rate ->
      {:ok,
       %Calculation{
         from_amount: from_amount,
         from_token: from_token,
         to_amount: from_amount * actual_rate,
         to_token: to_token,
         actual_rate: actual_rate,
         pair: pair,
         calculated_at: NaiveDateTime.utc_now()
       }}
    end)
  end

  def calculate(from_amount, from_token, to_amount, to_token) do
    if_pair_found(from_token, to_token, fn pair, actual_rate ->
      expected_to_amount = from_amount * actual_rate

      if expected_to_amount == to_amount do
        {:ok,
         %Calculation{
           from_amount: to_amount / actual_rate,
           from_token: from_token,
           to_amount: to_amount,
           to_token: to_token,
           actual_rate: actual_rate,
           pair: pair,
           calculated_at: NaiveDateTime.utc_now()
         }}
      else
        {:error, :exchange_invalid_rate}
      end
    end)
  end

  defp if_pair_found(from_token, to_token, fun) do
    preloads = [:from_token, :to_token]

    case ExchangePair.fetch_exchangable_pair(from_token, to_token, preload: preloads) do
      {:ok, pair, false} ->
        # Direct pair. Return the rate directly.
        fun.(pair, pair.rate)

      {:ok, pair, true} ->
        # Reversed pair. Return the inverted rate.
        fun.(pair, 1 / pair.rate)

      {:error, _} = error ->
        error
    end
  end
end
