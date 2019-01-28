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

defmodule EWallet.Web.APIDocs.ControllerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  Application.put_env(:ewallet, __MODULE__.Endpoint, error_handler: EWallet.Web.V1.ErrorHandler)

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ewallet
  end

  defmodule TestRouter do
    use Phoenix.Router
    use EWallet.Web.APIDocs, scope: "/some_scope"
  end

  setup_all do
    Endpoint.start_link()
    :ok
  end

  describe "/docs endpoints" do
    test "redirect to /docs.ui when calling /docs" do
      conn = get("/some_scope/docs")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/some_scope/docs.ui)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/some_scope/docs.ui"}
             end)
    end

    test "return the Swagger UI page when calling /docs.ui" do
      conn = get("/some_scope/docs.ui")

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ "<title>Swagger UI</title>"
    end

    test "return the yaml spec when calling /docs.yaml" do
      conn = get("/some_scope/docs.yaml")

      refute conn.halted
      assert conn.status == 200
      # Expects the spec to begin with "openapi:"
      assert conn.resp_body =~ ~r/^openapi:/
    end

    test "return the json spec when calling /docs.json" do
      conn = get("/some_scope/docs.json")

      refute conn.halted
      assert conn.status == 200
      # Expects the spec to begin with "openapi:"
      assert conn.resp_body =~ ~r/^{\n  \"openapi\"/
    end
  end

  describe "/errors endpoints" do
    test "redirect to /errors.ui when calling /errors" do
      conn = get("/some_scope/errors")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/some_scope/errors.ui)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/some_scope/errors.ui"}
             end)
    end

    test "returns the HTML page when calling /errors.ui" do
      conn = get("/some_scope/errors.ui")

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ ~r"<title>Error Codes for .*</title>"
    end

    test "returns the yaml spec when calling /errors.yaml" do
      conn = get("/some_scope/errors.yaml")

      refute conn.halted
      assert conn.status == 200
      # Expects the response to have a `code` key
      assert conn.resp_body =~ ~r/code:/
      # Expects the response to have a `description` key
      assert conn.resp_body =~ ~r/description:/
    end

    test "returns the json spec when calling /errors.json" do
      conn = get("/some_scope/errors.json")

      refute conn.halted
      assert conn.status == 200
      response = Poison.decode!(conn.resp_body)

      Enum.each(response, fn {_k, v} ->
        assert Map.has_key?(v, "code") &&
                 (Map.has_key?(v, "description") or Map.has_key?(v, "template"))
      end)
    end
  end

  defp get(path) do
    :get
    |> conn(path)
    |> put_private(:phoenix_endpoint, Endpoint)
    |> TestRouter.call([])
  end
end
