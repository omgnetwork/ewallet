defmodule EWallet.TokenFetcher do
  alias EWalletDB.{Account, Token}

  def fetch_from(%{"token_id" => token_id} = attrs, from) do
    with %Token{} = token <- Token.get_by(id: token_id) do
      from = Map.put(from, :from_token, token)
      {:ok, from}
    else
      error -> {:error, :token_not_found}
    end
  end

  def fetch_from(%{"from_token_id" => from_token_id} = attrs, from) do
    with %Token{} = token <- Token.get_by(id: from_token_id) do
      from = Map.put(from, :from_token, token)
      {:ok, from}
    else
      error -> {:error, :from_token_not_found}
    end
  end

  def fetch_to(%{"token_id" => token_id} = attrs, to) do
    with %Token{} = token <- Token.get_by(id: token_id) do
      to = Map.put(to, :to_token, token)
      {:ok, to}
    else
      error -> {:error, :token_not_found}
    end
  end

  def fetch_to(%{"to_token_id" => to_token_id} = attrs, to) do
    with %Token{} = token <- Token.get_by(id: to_token_id) do
      to = Map.put(to, :to_token, token)
      {:ok, to}
    else
      error -> {:error, :to_token_not_found}
    end
  end

  def fetch_exchange_account(%{"from_token_id" => from_token_id, "to_token_id" => to_token_id, "exchange_account_id" => exchange_account_id} = attrs) do
    case from_token_id == to_token_id do
      true ->
        {:ok, nil}
      false ->
        case Account.get(attrs["exchange_account_id"]) do
          nil ->
            {:error, :exchange_account_not_found}
          account ->
            {:ok, account}
        end
    end
  end

  def fetch_exchange_account(_) do
    {:ok, nil}
  end
end
