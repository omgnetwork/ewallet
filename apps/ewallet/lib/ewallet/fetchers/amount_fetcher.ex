defmodule EWallet.AmountFetcher do
  @moduledoc """
  Handles retrieval of amount from params for transactions.
  """
  alias EWallet.{Exchange, Helper}
  alias Utils.Helpers.Assoc

  #
  # Handles same-token transaction format
  #

  def fetch(
        %{"amount" => amount, "from_token_id" => from_token_id, "to_token_id" => to_token_id},
        _,
        _
      )
      when not is_nil(amount) and not is_nil(from_token_id) and not is_nil(to_token_id) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount` not allowed when exchanging values. Use `from_amount` and/or `to_amount`."}
  end

  def fetch(%{"amount" => amount}, from, to) when is_binary(amount) do
    handle_string_amount(amount, fn amount ->
      {:ok, Map.put(from, :from_amount, amount), Map.put(to, :to_amount, amount), %{}}
    end)
  end

  def fetch(%{"amount" => amount}, from, to) when is_integer(amount) do
    {:ok, Map.put(from, :from_amount, amount), Map.put(to, :to_amount, amount), %{}}
  end

  def fetch(%{"amount" => amount}, _from, _to) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount` is not an integer: #{amount}"}
  end

  #
  # Handles cross-token transaction format
  #

  # Converts a string `from_amount` to integer
  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount} = attrs, from, to)
      when is_binary(from_amount) and is_binary(to_amount) do
    handle_string_amount({from_amount, to_amount}, fn {from_amount, to_amount} ->
      attrs
      |> Map.put("from_amount", from_amount)
      |> Map.put("to_amount", to_amount)
      |> fetch(from, to)
    end)
  end

  def fetch(%{"from_amount" => from_amount} = attrs, from, to) when is_binary(from_amount) do
    handle_string_amount(from_amount, fn from_amount ->
      do_fetch(from_amount, attrs["to_amount"], from, to)
    end)
  end

  def fetch(%{"to_amount" => to_amount} = attrs, from, to) when is_binary(to_amount) do
    handle_string_amount(to_amount, fn to_amount ->
      do_fetch(attrs["from_amount"], to_amount, from, to)
    end)
  end

  # Proceeds with fetching if `from_amount` is provided
  def fetch(%{"from_amount" => from_amount} = attrs, from, to) when is_integer(from_amount) do
    do_fetch(from_amount, attrs["to_amount"], from, to)
  end

  # Proceeds with fetching if `to_amount` is provided
  def fetch(%{"to_amount" => to_amount} = attrs, from, to) when is_integer(to_amount) do
    do_fetch(attrs["from_amount"], to_amount, from, to)
  end

  # Returns error if neither `amount`, `from_amount` or `to_amount` is provided
  def fetch(_, _, _) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount`, `from_amount` or `to_amount` is required."}
  end

  # Uses `Exchange.validate/4` if both `from_amount` and `to_amount` are provided.
  defp do_fetch(from_amount, to_amount, from, to) when from_amount != nil and to_amount != nil do
    case Exchange.validate(from_amount, from[:from_token], to_amount, to[:to_token]) do
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

  # Uses `Exchange.calculate/4` if either `from_amount` or `to_amount` is provided.
  defp do_fetch(from_amount, to_amount, from, to) when from_amount != nil or to_amount != nil do
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

  defp do_fetch(_, _, _, _) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount`, `from_amount` or `to_amount` is required."}
  end

  defp handle_string_amount({amount_1, amount_2}, fun) do
    case Helper.strings_to_integers([amount_1, amount_2]) do
      [ok: amount_1, ok: amount_2] when is_integer(amount_1) and is_integer(amount_2) ->
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
