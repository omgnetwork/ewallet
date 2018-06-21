defmodule EWallet.AmountFetcher do
  def fetch_from(%{"amount" => amount}, from) when is_number(amount) do
    {:ok, Map.put(from, :from_amount, amount)}
  end

  def fetch_from(%{"amount" => _amount}, _from) do
    {:error, :invalid_parameter}
  end

  def fetch_from(%{"from_amount" => from_amount}, from) when is_number(from_amount) do
    {:ok, Map.put(from, :from_amount, from_amount)}
  end

  def fetch_from(%{"from_amount" => _from_amount}, _from) do
    {:error, :invalid_parameter}
  end

  def fetch_to(%{"amount" => amount}, to) when is_number(amount) do
    {:ok, Map.put(to, :to_amount, amount)}
  end

  def fetch_to(%{"amount" => _amount}, _to) do
    {:error, :invalid_parameter}
  end

  def fetch_to(%{"to_amount" => to_amount}, to) when is_number(to_amount) do
    {:ok, Map.put(to, :to_amount, to_amount)}
  end

  def fetch_to(%{"to_amount" => _to_amount}, _to) do
    {:error, :invalid_parameter}
  end
end
