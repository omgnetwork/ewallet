defmodule EWallet.TokenFetcher do
  @moduledoc """
  Handles retrieval of tokens from params for transactions.
  """
  alias EWalletDB.Token

  def fetch(%{"token_uuid" => token_uuid}) do
    with %Token{} = token <- Token.get_by(uuid: token_uuid) || :token_not_found,
         true <- token.enabled || :token_is_disabled do
      {:ok, token}
    else
      error -> {:error, error}
    end
  end

  def fetch(%{"token_id" => token_id}) do
    with %Token{} = token <- Token.get_by(id: token_id) || :token_not_found,
         true <- token.enabled || :token_is_disabled do
      {:ok, token}
    else
      error -> {:error, error}
    end
  end

  def fetch(%{"token_id" => token_id}, from, to) do
    with %Token{} = token <- Token.get_by(id: token_id) || :token_not_found,
         true <- token.enabled || :token_is_disabled do
      {:ok, Map.put(from, :from_token, token), Map.put(to, :to_token, token)}
    else
      error -> {:error, error}
    end
  end

  def fetch(%{"from_token_id" => from_token_id, "to_token_id" => to_token_id}, from, to) do
    with %Token{} = from_token <- Token.get_by(id: from_token_id) || :from_token_not_found,
         true <- from_token.enabled || :from_token_is_disabled,
         %Token{} = to_token <- Token.get_by(id: to_token_id) || :to_token_not_found,
         true <- to_token.enabled || :to_token_is_disabled do
      {:ok, Map.put(from, :from_token, from_token), Map.put(to, :to_token, to_token)}
    else
      error -> {:error, error}
    end
  end

  def fetch(_, _from, _to) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `token_id` or a pair of `from_token_id` and `to_token_id` is required."}
  end
end
