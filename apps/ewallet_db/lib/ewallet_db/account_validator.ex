defmodule EWalletDB.AccountValidator do
  @moduledoc """
  Specific validators for `EWalletDB.Account`.
  """
  import Ecto.Changeset
  alias EWalletDB.Account

  @doc """
  Validates that there can be only one master account in the system.
  """
  @spec validate_parent_id(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
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

  @doc """
  Validates that the given account is still within the given number of child levels
  relative to the master account.

  This validator makes a DB call to find out the child level of the given parent account.

  `child_level_limit` values:
    - `0` : valid if the account is the master account
    - `1` : valid if the account is the master account or its direct children
    - `2` : valid if the account is the master account, its direct children, or one more level down
    - ...
  """
  @spec validate_account_level(changeset :: Ecto.Changeset.t,
                               child_level_limit :: non_neg_integer()) :: Ecto.Changeset.t
  def validate_account_level(changeset, child_level_limit) do
    with {_, parent_id} <- fetch_field(changeset, :parent_id),
         depth          <- Account.get_depth(parent_id),
         true           <- depth >= child_level_limit
    do
      add_error(changeset,
                :parent_id,
                "is at the maximum child level",
                [validation: :account_level_limit])
    else
      _ -> changeset
    end
  end
end
