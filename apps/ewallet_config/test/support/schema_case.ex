defmodule EWalletConfig.SchemaCase do
  @moduledoc """
  This module defines common behaviors shared for EWalletConfig schema tests.

  Note that all macros below are quoted at `test ... do ... end` level
  with macro names starting with `test_`. This is so that in test cases,
  when these macros are used, they still resemble the original code.

  ## Example

  ### Original code:

  ```
  describe "SomeSchema.insert/1" do
    test "generates a UUID for SomeSchema" do
      # ...
      # lots of test code here
      # ...
    end

    test "generates inserted_at and updated_at values" do
      # ...
      # lots of test code here
      # ...
    end
  end
  ```

  ### Using macro:

  ```
  describe "SomeSchema.insert/1" do
    test_insert_generate_uuid SomeSchema
    test_insert_generate_timestamps SomeSchema
  end
  ```
  """
  alias Ecto.Adapters.SQL
  alias EWalletConfig.{Account, User}

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWalletConfig.SchemaCase
      alias Ecto.Adapters.SQL
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletConfig.Repo

      setup do
        Sandbox.checkout(Repo)
      end
    end
  end
end
