defmodule EWalletDB.Validator do
  @moduledoc """
  Custom validators that extend Ecto.Changeset's list of built-in validators.
  """
  alias Ecto.Changeset
  alias EWalletDB.Wallet

  @min_password_length Application.get_env(:ewallet_db, :min_password_length, 8)

  @doc """
  Validates that only one out of the provided fields can have value.
  """
  def validate_required_exclusive(changeset, attrs) when is_map(attrs) or is_list(attrs) do
    case count_fields_present(changeset, attrs) do
      1 ->
        changeset

      n when n > 1 ->
        Changeset.add_error(
          changeset,
          attrs,
          "only one must be present",
          validation: :only_one_required
        )

      _ ->
        Changeset.add_error(
          changeset,
          attrs,
          "can't all be blank",
          validation: :required_exclusive
        )
    end
  end

  @doc """
  Validates that either all or none the given fields are present.
  """
  def validate_required_all_or_none(changeset, attrs) do
    num_attrs = Enum.count(attrs)
    missing_attrs = Enum.filter(attrs, fn attr -> !field_present?(changeset, attr) end)

    case Enum.count(missing_attrs) do
      0 ->
        changeset

      ^num_attrs ->
        changeset

      _ ->
        Changeset.add_error(
          changeset,
          attrs,
          "either all or none of them must be present",
          validation: "all_or_none"
        )
    end
  end

  @doc """
  Validates that only one out of the provided fields can have value but
  both can be nil.
  """
  def validate_exclusive(changeset, attrs) when is_map(attrs) or is_list(attrs) do
    case count_fields_present(changeset, attrs) do
      n when n > 1 ->
        Changeset.add_error(
          changeset,
          attrs,
          "only one must be present",
          validation: :only_one_required
        )

      _ ->
        changeset
    end
  end

  def count_fields_present(changeset, attrs) do
    Enum.count(attrs, fn attr -> field_present?(changeset, attr) end)
  end

  def field_present?(changeset, attr) when is_atom(attr) do
    value = Changeset.get_field(changeset, attr)
    value && value != ""
  end

  def field_present?(changeset, {attr, nil}), do: field_present?(changeset, attr)

  def field_present?(changeset, {attr, attr_value}) do
    value = Changeset.get_field(changeset, attr)
    value && value != "" && value == attr_value
  end

  @doc """
  Validates that the value cannot be changed after it has been set.
  """
  def validate_immutable(changeset, key) do
    changed = Changeset.get_field(changeset, key)

    case Map.get(changeset.data, key) do
      nil -> changeset
      ^changed -> changeset
      _ -> Changeset.add_error(changeset, key, "can't be changed")
    end
  end

  @doc """
  Validates the given string with the password requirements.
  """
  def validate_password(nil),
    do: {:error, :password_too_short, [min_length: @min_password_length]}

  def validate_password(password) do
    with len when len >= @min_password_length <- String.length(password) do
      {:ok, password}
    else
      _ -> {:error, :password_too_short, [min_length: @min_password_length]}
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
  Validates email requirements.
  """
  def validate_email(changeset, key) do
    email = Changeset.get_field(changeset, key) || ""
    email_regex = ~r/^[^\@]+\@[^\@]+$/

    case Regex.match?(email_regex, email) do
      true ->
        changeset

      false ->
        Changeset.add_error(
          changeset,
          key,
          "must be a valid email address format",
          validation: :valid_email_address_format
        )
    end
  end

  @doc """
  Validates that a burn wallet cannot be used as sender.
  """
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
