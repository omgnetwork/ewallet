defmodule EWallet.AmountFetcher do
  @moduledoc """
  Handles retrieval of amount from params for transactions.
  """
  alias EWallet.Exchange

  def fetch(%{"amount" => _, "from_token_id" => _, "to_token_id" => _}, _, _) do
    {:error, :invalid_parameter,
     "'amount' not allowed when exchanging values. Use from_amount and/or to_amount."}
  end

  def fetch(%{"amount" => amount}, from, to) when is_number(amount) do
    {:ok, Map.put(from, :from_amount, amount), Map.put(to, :to_amount, amount)}
  end

  def fetch(%{"amount" => amount}, _from, _to) do
    {:error, :invalid_parameter, "'amount' is not a number: #{amount}"}
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_number(from_amount) and is_number(to_amount) do
    {:ok, Map.put(from, :from_amount, from_amount), Map.put(to, :to_amount, to_amount)}
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_number(from_amount) and is_nil(to_amount) do
    do_fetch(from_amount, nil, from, to)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, from, to)
      when is_nil(from_amount) and is_number(to_amount) do
    do_fetch(nil, to_amount, from, to)
  end

  def fetch(%{"from_amount" => from_amount, "to_amount" => to_amount}, _from, _to) do
    {:error, :invalid_parameter,
     "'from_amount' / 'to_amount' are not valid: #{from_amount} / #{to_amount}"}
  end

  def fetch(%{"from_amount" => from_amount}, from, to) when is_number(from_amount) do
    do_fetch(from_amount, nil, from, to)
  end

  def fetch(%{"to_amount" => to_amount}, from, to) when is_number(to_amount) do
    do_fetch(nil, to_amount, from, to)
  end

  def fetch_to(_, _to, _from) do
    {:error, :invalid_parameter, "'amount', 'from_amount' or 'to_amount' is required."}
  end

  defp do_fetch(from_amount, to_amount, from, to) do
    case Exchange.calculate(from_amount, from[:from_token], to_amount, to[:to_token]) do
      {:ok, calculation} ->
        {:ok, Map.put(from, :from_amount, calculation.from_amount),
         Map.put(to, :to_amount, calculation.to_amount)}

      error ->
        error
    end
  end
end
