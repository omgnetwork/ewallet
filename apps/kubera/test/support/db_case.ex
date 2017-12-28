defmodule Kubera.DBCase do
  @moduledoc """
  A test case template for tests that need to connect to the DB.
  """
  import KuberaDB.Factory
  alias KuberaDB.Repo

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Kubera.DBCase
      alias Ecto.Adapters.SQL.Sandbox
      alias KuberaDB.Repo

      setup do
        :ok = Sandbox.checkout(Repo)
      end
    end
  end

  def ensure_num_records(schema, num_required, attrs \\ %{}, count_field \\ :id) do
    num_remaining = num_required - Repo.aggregate(schema, :count, count_field)
    factory_name  = get_factory(schema)

    insert_list(num_remaining, factory_name, attrs)
    Repo.all(schema)
  end
end
