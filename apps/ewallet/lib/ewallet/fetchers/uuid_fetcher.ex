defmodule EWallet.UUIDFetcher do
  @moduledoc """
  Module responsible for turning external IDs into internal UUIDs.
  """
  alias EWalletDB.{Account, User}

  # Add more mappings if you wish to use this fetcher for other schemas.
  @mappings %{
    "account_id" => Account,
    "user_id" => User
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

  defp replace_external_id(key, value, external_id: true) when is_atom(key) do
    replace_external_id(Atom.to_string(key), value, external_id: true)
  end

  defp replace_external_id(key, value, external_id: true) do
    schema = @mappings[key]
    uuid_key = String.replace(key, "_id", "_uuid")

    load_record(schema, uuid_key, key, value)
  end

  defp replace_external_id(key, value, external_id: false), do: {key, value}

  defp load_record(nil, _, key, value), do: {key, value}

  defp load_record(schema, uuid_key, _key, value) do
    value
    |> schema.get()
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
