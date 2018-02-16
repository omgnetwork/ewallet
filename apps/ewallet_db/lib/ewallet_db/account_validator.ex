defmodule EWalletDB.AccountValidator do
  @moduledoc """
  Specific validators for `EWalletDB.Account`.
  """
  import Ecto.Changeset
  alias EWalletDB.Account

  @doc """
  Validates that there can be only one master account in the system.
  """
  def validate_parent_id(changeset) do
    # Require a `parent_id` if:
    #   1. This changeset has `parent_id` == nil
    #   2. The master account already exists
    #   3. This changeset is not for the master account
    with nil          <- get_field(changeset, :parent_id),
         %{} = master <- Account.get_master_account(),
         false        <- master.id == get_field(changeset, :id)
    do
      validate_required(changeset, :parent_id)
    else
      _ -> changeset
    end
  end
end
