defmodule KuberaAPI.EndpointCase do
  @moduledoc """
  This module defines common behaviors shared between V1 endpoint tests.
  """

  def v1 do
    quote do
      import KuberaDB.Factory
      alias Ecto.Adapters.SQL.Sandbox
      alias KuberaDB.{Repo, Account, Key}

      @header_accept "application/vnd.omisego.v1+json" # The expected response version
      @expected_version "1" # The expected response version

      @access_key "test_access_key"
      @secret_key "test_secret_key"
      @header_auth "OMGServer " <> Base.encode64(@access_key <> ":" <> @secret_key)

      # Setup sandbox and provider's access/secret keys
      setup do
        :ok = Sandbox.checkout(Repo)

        {:ok, account} =
          :account
          |> params_for(%{name: "Test Account"})
          |> Account.insert()

        :key
        |> params_for(%{
            account: account,
            access_key: @access_key,
            secret_key: @secret_key
          })
        |> Key.insert()

        :ok
      end
    end
  end

  defmacro __using__(version) when is_atom(version) do
    apply(__MODULE__, version, [])
  end
end
