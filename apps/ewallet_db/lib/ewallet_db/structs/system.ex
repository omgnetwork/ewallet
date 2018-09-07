defmodule EWalletDB.System do
  defstruct uuid: "00000000-0000-0000-0000-000000000000"

  @audit_schema "system"
  def audit_schema, do: @audit_schema
end
