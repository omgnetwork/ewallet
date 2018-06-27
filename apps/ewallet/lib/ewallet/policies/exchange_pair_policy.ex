defmodule EWallet.ExchangePairPolicy do
  @moduledoc """
  The authorization policy for exchange pairs.
  """
  alias EWalletDB.{User, Key}
  @behaviour Bodyguard.Policy

  # Any user can list exchange pairs
  def authorize(:all, _user_or_key, nil), do: true

  # Any user can get an exchange pair
  def authorize(:get, _user_or_key, _exchange_pair_id), do: true

  # Only users with an admin role on master account can create an exchange pair
  def authorize(:create, %User{} = user, nil) do
    User.master_admin?(user.id)
  end

  def authorize(:create, %Key{} = _key, nil) do
    true
  end

  # Only users with an admin role on master account can edit an exchange pair
  def authorize(:update, %User{} = user, _exchange_pair_id) do
    User.master_admin?(user.id)
  end

  def authorize(:update, %Key{} = _key, _exchange_pair_id) do
    true
  end

  # Only users with an admin role on master account can delete an exchange pair
  def authorize(:delete, %User{} = user, _exchange_pair_id) do
    User.master_admin?(user.id)
  end

  def authorize(:delete, %Key{} = _key, _exchange_pair_id) do
    true
  end

  # Catch-all: deny everything else
  def authorize(_, _, _), do: false
end
