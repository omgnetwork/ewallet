defmodule EWallet.UserFetcher do
  @moduledoc """
  Handles the retrieval of users from the eWallet database.
  """
  alias EWalletDB.{User}

  @spec fetch(String.t()) :: {:ok, User.t()} | {:error, Atom.t()}
  def fetch(%{"user_id" => user_id}) do
    with %User{} = user <- User.get(user_id) || :user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  @spec fetch(String.t()) :: {:ok, User.t()} | {:error, Atom.t()}
  def fetch(%{"provider_user_id" => provider_user_id}) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found do
      {:ok, user}
    else
      error -> {:error, error}
    end
  end

  def fetch(_), do: {:error, :invalid_parameter}
end
