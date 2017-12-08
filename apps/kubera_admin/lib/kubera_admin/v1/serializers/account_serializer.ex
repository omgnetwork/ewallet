defmodule KuberaAdmin.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """

  def to_json(account) when is_map(account) do
    %{
      object: "account",
      id: account.id,
      name: account.name,
      description: account.description,
      master: account.master
    }
  end
  def to_json(accounts) when is_list(accounts) do
    Enum.map(accounts, &to_json/1)
  end
end
