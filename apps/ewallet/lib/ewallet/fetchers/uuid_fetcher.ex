defmodule EWallet.UUIDFetcher do
  @moduledoc """
  Module responsible for turning external IDs into internal UUIDs.
  """
  alias EWalletDB.{Account, Token, User}

  # Add more mappings if you wish to use this fetcher for other schemas.
  @mappings %{
    "account_id" => {Account, :id, "account_uuid"},
    "user_id" => {User, :id, "user_uuid"},
    "provider_user_id" => {User, :provider_user_id, "user_uuid"},
    "from_token_id" => {Token, :id, "from_token_uuid"},
    "to_token_id" => {Token, :id, "to_token_uuid"},
  }

  @doc """
  Turns external IDs into internal IDs. If a record is found, it will
  also be added to the attributes.

  Example:

  UUIDFetcher.replace_external_ids(%{
    "account_id" => "some_external_id"
  })

  => %{
    "account_uuid" => "some_internal_id",
    "account" => %Account{ ... }
  }

  """
  @spec replace_external_ids(map()) :: map()
  def replace_external_ids(attrs) do
    attrs
    |> Enum.map(fn {key, value} ->
      external_id? = String.match?(key, ~r/_id$/)
      replace_external_id(key, value, external_id: external_id?)
    end)
    |> List.flatten()
    |> Enum.into(%{})
  end

  defp replace_external_id(key, value, external_id: true) do
    load_record(@mappings[key], key, value)
  end

  defp replace_external_id(key, value, external_id: false), do: {key, value}

  defp load_record(nil, key, value), do: {key, value}

  defp load_record({schema, internal_field, uuid_key}, _key, value) do
    [{internal_field, value}]
    |> schema.get_by()
    |> extract_uuid(uuid_key)
  end

  defp extract_uuid(nil, uuid_key) do
    [
      {uuid_key, nil},
      {String.replace(uuid_key, "_uuid", ""), nil}
    ]
  end

  defp extract_uuid(record, uuid_key) do
    [
      {uuid_key, record.uuid},
      {String.replace(uuid_key, "_uuid", ""), record}
    ]
  end
end
