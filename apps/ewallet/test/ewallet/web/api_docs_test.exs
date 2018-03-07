defmodule EWallet.Web.APIDocsTest do
  use ExUnit.Case
  use Plug.Test

  defmodule TestRouter do
    use Phoenix.Router
    use EWallet.Web.APIDocs, scope: "/some_scope"
  end

  describe "__using__/1" do
    test "redirects to /docs.ui when calling /docs" do
      conn =
        :get
        |> conn("/some_scope/docs")
        |> TestRouter.call([])

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/some_scope/docs.ui)
      assert Enum.any?(conn.resp_headers, fn(header) ->
        header == {"location", "/some_scope/docs.ui"}
      end)
    end

    test "returns the Swagger UI page when calling /docs.ui" do
      conn =
        :get
        |> conn("/some_scope/docs.ui")
        |> TestRouter.call([])

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ "<title>Swagger UI</title>"
    end

    test "returns the yaml spec when calling /docs.yaml" do
      conn =
        :get
        |> conn("/some_scope/docs.yaml")
        |> put_private(:phoenix_endpoint, EWalletAPI.Endpoint)
        |> TestRouter.call([])

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ ~r/^openapi:/ # Expects the spec to begin with "openapi:"
    end
  end
end
