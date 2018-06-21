defmodule EWallet.AmountFetcher do
  def fetch_from(%{"amount" => amount}, from) do
    {:ok, Map.put(from, :from_amount, amount)}
  end

  def fetch_from(%{"from_amount" => from_amount}, from) do
    {:ok, Map.put(from, :from_amount, from_amount)}
  end

  def fetch_to(%{"amount" => amount}, to) do
    {:ok, Map.put(to, :to_amount, amount)}
  end

  def fetch_to(%{"to_amount" => to_amount}, to) do
    {:ok, Map.put(to, :to_amount, to_amount)}
  end
end
