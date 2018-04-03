defmodule EWallet.Web.APIDocs.ControllerTest do
  use ExUnit.Case
  use Plug.Test

  defmodule TestRouter do
    use Phoenix.Router
    use EWallet.Web.APIDocs, scope: "/some_scope"
  end

  describe "/docs endpoints" do
    test "redirect to /docs.ui when calling /docs" do
      conn = get("/some_scope/docs")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/some_scope/docs.ui)
      assert Enum.any?(conn.resp_headers, fn(header) ->
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
      assert conn.resp_body =~ ~r/^openapi:/ # Expects the spec to begin with "openapi:"
    end
  end

  describe "/errors endpoints" do
    test "redirect to /errors.ui when calling /errors" do
      conn = get("/some_scope/errors")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/some_scope/errors.ui)
      assert Enum.any?(conn.resp_headers, fn(header) ->
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
      assert conn.resp_body =~ ~r/code:/ # Expects the response to have a `code` key
      assert conn.resp_body =~ ~r/description:/ # Expects the response to have a `description` key
    end

    test "returns the json spec when calling /errors.json" do
      conn = get("/some_scope/errors.json")

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ ~r/"code":/ # Expects the response to have a `code` key
      assert conn.resp_body =~ ~r/"description":/ # Expects the response to have a `description` key
    end
  end

  defp get(path) do
    :get
    |> conn(path)
    |> put_private(:phoenix_endpoint, EWalletAPI.Endpoint)
    |> TestRouter.call([])
  end
end
