defmodule EWalletDB.Schema do
  @moduledoc """
  The module that prepares commonly-used functionalities for eWallet DB's schemas.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      use EWalletDB.SoftDelete
      import Ecto.{Changeset, Query}
      import EWalletDB.Types.ExternalID, only: [external_id: 1]
      alias Ecto.UUID
      alias EWalletDB.Repo
    end
  end
end
