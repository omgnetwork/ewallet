defmodule Kubera.Transactions.RecordFetcher do
  @moduledoc """
  Handles the logic for fetching the user and minted_token.
  """
  alias KuberaDB.{User, MintedToken}

  def fetch_user_and_minted_token(provider_user_id, token_friendly_id) do
    user = User.get_by_provider_user_id(provider_user_id)
    minted_token = MintedToken.get(token_friendly_id)
    fetch(user, minted_token)
  end
  defp fetch(nil, _), do: {:error, :provider_user_id_not_found}
  defp fetch(_, nil), do: {:error, :minted_token_not_found}
  defp fetch(user, minted_token), do: {:ok, user, minted_token}
end
