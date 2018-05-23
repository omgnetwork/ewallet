defmodule EWallet.UUIDFetcher do
  @moduledoc """
  Module responsible for turning external IDs into internal UUIDs.
  """
  alias EWalletDB.{Account, User}

  @mappings %{
    account_id: Account,
    user_id: User
  }

  def replace_external_ids(attrs) do
    attrs
    |> Enum.map(fn {key, value} ->
      case String.match?(key, ~r/_id$/) do
        true ->
          with external_id <- String.to_existing_atom(key),
               schema <- @mappings[external_id],
               key = String.replace(key, "_id", "_uuid") do
            case schema.get(value) do
              nil ->
                {key, nil}

              record ->
                {key, record.uuid}
            end
          else
            error ->
              error
          end

        false ->
          {key, value}
      end
      # rescue
    end)
    |> Enum.into(%{})
  end
end
