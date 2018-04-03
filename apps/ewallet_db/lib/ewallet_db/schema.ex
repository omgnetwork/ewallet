defmodule EWalletDB.Schema do
  @moduledoc """
  The module that prepares commonly-used functionalities for eWallet DB's schemas.

  You will notice that most schemas contain an `id` and `external_id`. This allows
  the database's primary keys to be independent from the implementation. The `id` is
  only used within the models, schemas, joins and other database operations.

  The rest of the codebase should interact with `external_id`s instead. Any reference
  to an `id` outside the schema modules should refer to the `external_id`.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      use EWalletDB.SoftDelete
      import Ecto.{Changeset, Query}
      import EWalletDB.Types.ExternalID, only: [external_id: 1]
      alias Ecto.UUID
      alias EWalletDB.Repo

      @type t :: %__MODULE__{}

      @behaviour Access

      def fetch(term, key) when is_map(term), do: Map.fetch(term, key)
      def get(term, key, default) when is_map(term), do: Map.get(term, key, default)
      def get_and_update(data, key, function) when is_map(data), do: Map.get_and_update(data, key, function)
      def pop(data, key) when is_map(data), do: Map.pop(data, key)
    end
  end
end
