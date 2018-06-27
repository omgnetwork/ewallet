defmodule EWallet.TokenFetcher do
  @moduledoc """
  Handles retrieval of tokens from params for transactions.
  """
  alias EWalletDB.{Account, Token}

  def fetch(%{"token_id" => token_id}, from, to) do
    with %Token{} = token <- Token.get_by(id: token_id) do
      {:ok, Map.put(from, :from_token, token), Map.put(to, :to_token, token)}
    else
      _error -> {:error, :token_not_found}
    end
  end

  def fetch(%{"from_token_id" => from_token_id, "to_token_id" => to_token_id}, from, to) do
    with %Token{} = from_token <- Token.get_by(id: from_token_id) || :from_token_not_found,
         %Token{} = to_token <- Token.get_by(id: to_token_id) || :to_token_not_found do
      {:ok, Map.put(from, :from_token, from_token), Map.put(to, :to_token, to_token)}
    else
      error -> {:error, error}
    end
  end

  def fetch(_, _from, _to) do
    {:error, :invalid_parameter,
     "'token_id' or a pair 'from_token_id'/'to_token_id' is required."}
  end

  def fetch_exchange_account(%{
        "from_token_id" => from_token_id,
        "to_token_id" => to_token_id,
        "exchange_account_id" => exchange_account_id
      }) do
    case from_token_id == to_token_id do
      true ->
        {:ok, nil}

      false ->
        case Account.get(exchange_account_id) do
          nil ->
            {:error, :exchange_account_not_found}

          account ->
            {:ok, account.uuid}
        end
    end
  end

  def fetch_exchange_account(%{
        "from_token_id" => from_token_id,
        "to_token_id" => to_token_id,
      }) do
    case from_token_id == to_token_id do
      true ->
        {:ok, nil}

      false ->
        {:error, :invalid_parameter, "'exchange_account_id is required.'"}
    end
  end

  def fetch_exchange_account(_) do
    {:ok, nil}
  end
end
