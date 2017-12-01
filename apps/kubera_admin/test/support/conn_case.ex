defmodule KuberaAdmin.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  use ExUnit.CaseTemplate
  use Phoenix.ConnTest
  alias Ecto.Adapters.SQL.Sandbox
  alias KuberaDB.Repo

  # Attributes required by Phoenix.ConnTest
  @endpoint KuberaAdmin.Endpoint

  # Attributes for all calls
  @expected_version "1" # The expected response version
  @header_accept "application/vnd.omisego.v1+json" # The expected response version

  # Attributes for client calls
  @username "test_username"
  @password "test_password"
  @provider_user_id "test_provider_user_id"

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import KuberaAdmin.ConnCase
      import KuberaAdmin.Router.Helpers
      import KuberaDB.Factory

      # Reiterate all module attributes from `KuberaAdmin.ConnCase`
      @endpoint unquote(@endpoint)

      @expected_version unquote(@expected_version)
      @header_accept unquote(@header_accept)

      @username unquote(@username)
      @password unquote(@password)
      @provider_user_id unquote(@provider_user_id)
    end
  end

  setup do
    :ok = Sandbox.checkout(Repo)

    # Setup could return all the inserted credentials using ExUnit context
    # by returning {:ok, context_map}. But it would make the code
    # much less readable, i.e. `test "my test name", context do`,
    # and access using `context[:attribute]`.
    :ok
  end

  @doc """
  A helper function that generates a valid public request
  with given path and data, and return the parsed JSON response.
  """
  def public_request(path, data \\ %{}, status \\ :ok) when is_binary(path) and byte_size(path) > 0 do
    build_conn()
    |> put_req_header("accept", @header_accept)
    |> post(path, data)
    |> json_response(status)
  end
end
