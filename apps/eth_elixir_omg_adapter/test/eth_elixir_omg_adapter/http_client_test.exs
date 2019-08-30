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

defmodule EthElixirOmgAdapter.HttpClientTest do
  use EthElixirOmgAdapter.EthElixirOmgAdapterCase, async: true

  alias EthElixirOmgAdapter.{HttpClient, ResponseBody}

  describe "post_request/2" do
    test "success" do
      data = %{}

      {status, response} =
        %{"expect" => "success", "data" => data}
        |> Jason.encode!()
        |> HttpClient.post_request("post_request_test")

      assert status == :ok
      assert response == data
    end

    test "handled failure" do
      code = "some_code"

      {status, error, message} =
        %{"expect" => "handled_failure", "code" => code}
        |> Jason.encode!()
        |> HttpClient.post_request("post_request_test")

      assert status == :error
      assert error == :elixir_omg_bad_request
      assert message == [error_code: code]
    end

    test "unhandled failure" do
      {status, error, message} =
        %{"expect" => "unhandled_failure"}
        |> Jason.encode!()
        |> HttpClient.post_request("post_request_test")

      assert status == :error
      assert error == :elixir_omg_bad_request
      assert message == [error_code: "invalid response"]
    end

    test "decoding failure" do
      {status, error, message} =
        %{"expect" => "decoding_failure"}
        |> Jason.encode!()
        |> HttpClient.post_request("post_request_test")

      assert status == :error
      assert error == :elixir_omg_bad_request
      assert message == [error_code: "decoding error"]
    end
  end
end
