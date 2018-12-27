# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.Web.V1.ErrorHandlerTest do
  # async: false due to `Application.put_env/3` for sentry reporting
  use EWallet.DBCase, async: false
  alias EWallet.Web.V1.ErrorHandler
  alias Ecto.Changeset
  alias Plug.Conn

  describe "build_error/3" do
    test "returns an error object when given an error code and changeset" do
      errors = %{
        error_code: %{
          code: "error:error_code",
          description: "Error description."
        }
      }

      data = %{}
      types = %{name: :string}

      changeset =
        {data, types}
        |> Changeset.change()
        |> Changeset.validate_required(:name)

      expected = %{
        object: "error",
        code: errors[:error_code].code,
        description: errors[:error_code].description <> " `name` can't be blank.",
        messages: %{"name" => [:required]}
      }

      assert ErrorHandler.build_error(:error_code, changeset, errors) == expected
    end

    test "returns an error object when given a valid code and an arbitary description" do
      errors = %{
        error_code: %{
          code: "error:error_code",
          description: "Error description."
        }
      }

      description = "arbitary_description"

      expected = %{
        object: "error",
        code: errors[:error_code].code,
        description: description,
        messages: nil
      }

      assert ErrorHandler.build_error(:error_code, description, errors) == expected
    end

    test "handles insufficient funds error" do
      errors = %{
        error_code: %{
          code: "error:error_code",
          template:
            "The specified wallet (%{address}) does not contain enough funds. " <>
              "Available: %{current_amount} %{token_id} - Attempted debit: " <>
              "%{amount_to_debit} %{token_id}"
        }
      }

      token = insert(:token)

      data = %{
        "address" => "some_wallet_address",
        "current_amount" => 1 * token.subunit_to_unit,
        "amount_to_debit" => 10 * token.subunit_to_unit,
        "token_id" => token.id
      }

      expected = %{
        object: "error",
        code: errors[:error_code].code,
        description:
          "The specified wallet (#{data["address"]}) does not contain enough funds. " <>
            "Available: 1 #{token.id} - Attempted debit: 10 #{token.id}",
        messages: nil
      }

      assert ErrorHandler.build_error(:error_code, data, errors) == expected
    end

    test "returns an error object when given a valid code and templating data" do
      errors = %{
        error_code: %{
          code: "error:error_code",
          template: "Error template. Value is: '%{value}'."
        }
      }

      expected = %{
        object: "error",
        code: errors[:error_code].code,
        description: "Error template. Value is: 'ABCD'.",
        messages: nil
      }

      assert ErrorHandler.build_error(:error_code, %{"value" => "ABCD"}, errors) == expected
    end
  end

  describe "build_error/2" do
    test "returns an error object when the given code matches the error code mapping" do
      errors = %{
        error_code: %{
          code: "error:error_code",
          description: "Error description."
        }
      }

      expected = %{
        object: "error",
        code: errors[:error_code].code,
        description: "Error description.",
        messages: nil
      }

      assert ErrorHandler.build_error(:error_code, errors) == expected
    end

    test "sends a report to sentry when the given error code could not be found" do
      errors = %{
        # This is indirectly required in order to generate
        # the proper error response for the unknown error.
        internal_server_error: %{
          code: "server:internal_server_error",
          description: "Something went wrong on the server."
        }
      }

      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        assert conn.halted == false
        assert conn.method == "POST"
        assert conn.request_path == "/api/1/store/"

        Conn.resp(conn, 200, ~s'{"id": "1234"}')
      end)

      original_dsn = Application.get_env(:sentry, :dsn)
      original_included_envs = Application.get_env(:sentry, :included_environments)

      Application.put_env(:sentry, :dsn, "http://public@localhost:#{bypass.port}/1")
      Application.put_env(:sentry, :included_environments, [:test | original_included_envs])

      expected = %{
        object: "error",
        code: errors[:internal_server_error].code,
        description: "Something went wrong on the server.",
        messages: nil
      }

      assert ErrorHandler.build_error(:unknown_code, errors) == expected

      # Because Bypass takes some time to serve the endpoint and Sentry uses
      # `Task.Supervisor.async_nolink/3` deep inside its code, the only way
      # to wait for the reporting to complete is to sleep...
      :timer.sleep(1000)

      Application.put_env(:sentry, :dsn, original_dsn)
      Application.put_env(:sentry, :included_environments, original_included_envs)
    end
  end
end
