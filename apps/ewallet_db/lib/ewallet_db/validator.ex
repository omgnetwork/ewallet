defmodule EWalletDB.Validator do
  @moduledoc """
  Custom validators that extend Ecto.Changeset's list of built-in validators.
  """
  alias Ecto.Changeset
  alias EWalletDB.Wallet

  @doc """
  Gets the minimum password length from settings.
  """
  def min_password_length do
    case Application.get_env(:ewallet_db, :min_password_length) do
      nil ->
        8

      value ->
        value
    end
  end

  def validate_from_wallet_identifier(changeset) do
    from = Changeset.get_field(changeset, :from)
    wallet = Wallet.get(from)

    case Wallet.burn_wallet?(wallet) do
      true ->
        Changeset.add_error(
          changeset,
          :from,
          "can't be the address of a burn wallet",
          validation: :burn_wallet_as_sender_not_allowed
        )

      false ->
        changeset
    end
  end

  @doc """
  Validates the given string with the password requirements.
  """
  def validate_password(nil),
    do: {:error, :password_too_short, [min_length: min_password_length()]}

  def validate_password(password) do
    min_length = min_password_length()

    with len when len >= min_length <- String.length(password) do
      {:ok, password}
    else
      _ -> {:error, :password_too_short, [min_length: min_length]}
    end
  end

  @doc """
  Validates password requirements on the given changeset and key.
  """
  def validate_password(changeset, key) do
    password = Changeset.get_field(changeset, key)

    case validate_password(password) do
      {:ok, _} ->
        changeset

      {:error, :password_too_short, data} ->
        Changeset.add_error(changeset, key, "must be #{data[:min_length]} characters or more")
    end
  end

  @doc """
  Validates that the values are different.
  """
  def validate_different_values(changeset, key_1, key_2) do
    value_1 = Changeset.get_field(changeset, key_1)
    value_2 = Changeset.get_field(changeset, key_2)

    case value_1 == value_2 do
      true ->
        Changeset.add_error(
          changeset,
          key_2,
          "can't have the same value as `#{key_1}`",
          validation: :different_values
        )

      false ->
        changeset
    end
  end
end
