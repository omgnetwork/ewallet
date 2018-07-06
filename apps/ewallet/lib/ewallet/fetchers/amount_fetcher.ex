defmodule EWallet.AmountFetcher do
  @moduledoc """
  Handles retrieval of amount from params for transactions.
  """
  alias EWallet.{Exchange, Helper}
  alias EWalletDB.Helpers.Assoc

  def fetch(
        %{"amount" => amount, "from_token_id" => from_token_id, "to_token_id" => to_token_id},
        _,
        _
      )
      when not is_nil(amount) and not is_nil(from_token_id) and not is_nil(to_token_id) do
    {:error, :invalid_parameter,
     "'amount' not allowed when exchanging values. Use from_amount and/or to_amount."}
  end

  def fetch(%{"amount" => amount}, from, to) when is_integer(amount) do
    {:ok, Map.put(from, :from_amount, amount), Map.put(to, :to_amount, amount), %{}}
  end

  def fetch(%{"amount" => amount}, from, to) when is_binary(amount) do
    handle_string_amount(amount, fn amount ->
      {:ok, Map.put(from, :from_amount, amount), Map.put(to, :to_amount, amount), %{}}
    end)
  end

  def fetch(%{"amount" => amount}, _from, _to) do
    {:error, :invalid_parameter, "'amount' is not a number: #{amount}"}
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_number(from_amount) and is_number(to_amount) do
    {:ok, Map.put(from, :from_amount, from_amount), Map.put(to, :to_amount, to_amount), %{}}
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_binary(from_amount) and is_binary(to_amount) do
    handle_string_amount({from_amount, to_amount}, fn {from_amount, to_amount} ->
      {:ok, Map.put(from, :from_amount, from_amount), Map.put(to, :to_amount, to_amount), %{}}
    end)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_number(from_amount) and is_nil(to_amount) do
    do_fetch(from_amount, nil, from, to)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_binary(from_amount) and is_nil(to_amount) do
    handle_string_amount(from_amount, fn from_amount ->
      do_fetch(from_amount, nil, from, to)
    end)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_nil(from_amount) and is_number(to_amount) do
    do_fetch(nil, to_amount, from, to)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_nil(from_amount) and is_binary(to_amount) do
    handle_string_amount(to_amount, fn to_amount ->
      do_fetch(nil, to_amount, from, to)
    end)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, _from, _to) do
    {:error, :invalid_parameter,
     "'from_amount' / 'to_amount' are not valid: #{from_amount} / #{to_amount}"}
  end

  def fetch(%{"from_amount" => from_amount}, from, to) when is_number(from_amount) do
    do_fetch(from_amount, nil, from, to)
  end

  def fetch(%{"from_amount" => from_amount}, from, to) when is_binary(from_amount) do
    handle_string_amount(from_amount, fn from_amount ->
      do_fetch(from_amount, nil, from, to)
    end)
  end

  def fetch(%{"to_amount" => to_amount}, from, to) when is_number(to_amount) do
    do_fetch(nil, to_amount, from, to)
  end

  def fetch(%{"to_amount" => to_amount}, from, to) when is_binary(to_amount) do
    handle_string_amount(to_amount, fn to_amount ->
      do_fetch(nil, to_amount, from, to)
    end)
  end

  def fetch(_, _to, _from) do
    {:error, :invalid_parameter, "'amount', 'from_amount' or 'to_amount' is required."}
  end

  defp do_fetch(from_amount, to_amount, from, to) do
    case Exchange.calculate(from_amount, from[:from_token], to_amount, to[:to_token]) do
      {:ok, calculation} ->
        exchange =
          %{}
          |> Map.put(:actual_rate, calculation.actual_rate)
          |> Map.put(:calculated_at, calculation.calculated_at)
          |> Map.put(:pair_uuid, Assoc.get(calculation, [:pair, :uuid]))

        {:ok, Map.put(from, :from_amount, calculation.from_amount),
         Map.put(to, :to_amount, calculation.to_amount), exchange}

      error ->
        error
    end
  end

  defp handle_string_amount({amount_1, amount_2}, fun) do
    case Helper.strings_to_integers([amount_1, amount_2]) do
      [amount_1, amount_2] when is_integer(amount_1) and is_integer(amount_2) ->
        fun.({amount_1, amount_2})

      error ->
        error
    end
  end

  defp handle_string_amount(amount, fun) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} -> fun.(amount)
      error -> error
    end
  end
end
