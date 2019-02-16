# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.ErrorHandlerTest do
  use ExUnit.Case
  use EWalletAPI.ConnCase, async: true
  import Ecto.Changeset
  alias EWalletAPI.V1.ErrorHandler
  alias Poison.Parser

  defmodule TestSchema do
    use Ecto.Schema

    schema "test_schema" do
      field(:field1, :string)
      field(:field2, :string)
      field(:field3, :string)
    end
  end

  describe "handle_error/2" do
    test "returns default code and description" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided.",
          "messages" => nil
        }
      }

      {:ok, output} =
        build_conn()
        |> ErrorHandler.handle_error(:invalid_parameter)
        |> parse_body()

      assert output == expected
    end

    test "returns :invalid_parameter with the invalid params if changeset provided" do
      changeset =
        %TestSchema{}
        |> cast(%{field1: "testvalue"}, [:field1, :field2, :field3])
        |> validate_required([:field1, :field2, :field3])

      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" =>
            "Invalid parameter provided." <>
              " `field2` can't be blank." <> " `field3` can't be blank.",
          "messages" => %{
            "field2" => ["required"],
            "field3" => ["required"]
          }
        }
      }

      {:ok, output} =
        build_conn()
        |> ErrorHandler.handle_error(:invalid_parameter, changeset)
        |> parse_body()

      assert output == expected
    end

    test "returns :invalid_version with provided accept header" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_version",
          "description" => "Invalid API version. Given: 'invalid_header'.",
          "messages" => nil
        }
      }

      {:ok, output} =
        build_conn()
        |> ErrorHandler.handle_error(:invalid_version, %{
          "accept" => "invalid_header"
        })
        |> parse_body()

      assert output == expected
    end
  end

  defp parse_body(conn) do
    conn
    |> Map.get(:resp_body)
    |> Parser.parse()
  end
end
