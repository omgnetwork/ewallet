defmodule EWallet.UserFetcher do
  @moduledoc """
  Handles the retrieval of users from the eWallet database.
  """
  alias EWalletDB.{User}

  @spec get(String.t()) :: {:ok, User.t()} | {:error, Atom.t()}
  def get(%{"user_id" => user_id}) do
    with %User{} = user <- User.get(user_id) || :user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  @spec get(String.t()) :: {:ok, User.t()} | {:error, Atom.t()}
  def get(%{"provider_user_id" => provider_user_id}) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  def get(_), do: {:error, :invalid_parameter}
end
