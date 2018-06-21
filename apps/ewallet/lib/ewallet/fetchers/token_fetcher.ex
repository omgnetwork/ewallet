defmodule EWallet.TokenFetcher do
  alias EWalletDB.Token
  
  def fetch_from(%{"token_id" => token_id} = attrs, from_or_to) do
    with %Token{} = token <- Token.get_by(id: token_id) do
      from_or_to
      |> Map.put(:from_token, token)
    else
      error -> {:error, :token_not_found}
    end
  end

  def fetch_from(%{"from_token_id" => from_token_id} = attrs, from) do
    with %Token{} = token <- Token.get_by(id: from_token_id) do
      Map.put(from, :from_token, token)
    else
      error -> {:error, :from_token_not_found}
    end
  end

  def fetch_to(%{"token_id" => token_id} = attrs, from_or_to) do
    with %Token{} = token <- Token.get_by(id: token_id) do
      from_or_to
      |> Map.put(:to_token, token)
    else
      error -> {:error, :token_not_found}
    end
  end

  def fetch_to(%{"to_token_id" => to_token_id} = attrs, to) do
    with %Token{} = token <- Token.get_by(id: to_token_id) do
      Map.put(to, :to_token, token)
    else
      error -> {:error, :to_token_not_found}
    end
  end
end
