defmodule EWalletDB.Auditable do
  @moduledoc """
  Allows audit for Ecto records.
  """
  import Ecto.Changeset
  alias EWalletDB.Audit
  alias EWalletConfig.Types.VirtualStruct

  @doc false
  defmacro __using__(_) do
    quote do
      import EWalletDB.Auditable
      alias EWalletDB.Auditable
    end
  end

  @doc """
  A macro that adds the `:originator` virtual field to a schema.
  """
  defmacro auditable do
    quote do
      field(:originator, VirtualStruct, virtual: true)
    end
  end

  @doc """
  Prepares a changeset for audit.
  """
  def cast_and_validate_required_for_audit(record, attrs, cast \\ [], required \\ []) do
    record
    |> Map.delete(:originator)
    |> cast(attrs, [:originator | cast])
    |> validate_required([:originator | required])
  end

  def insert_with_audit(changeset, opts \\ [], multi \\ Multi.new()) do
    Audit.insert_record_with_audit(changeset, opts, multi)
  end

  def update_with_audit(changeset, opts \\ [], multi \\ Multi.new()) do
    Audit.update_record_with_audit(changeset, opts, multi)
  end
end
