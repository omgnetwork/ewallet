defmodule EWallet.Web.APIDocs.ControllerTest do
  use ExUnit.Case
  use Plug.Test

  defmodule TestRouter do
    use Phoenix.Router
    use EWallet.Web.APIDocs, scope: "/api/some_scope"
  end

  describe "/docs endpoints" do
    test "redirect to /docs.ui when calling /docs" do
      conn = get("/api/some_scope/docs")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/api/some_scope/docs.ui)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/api/some_scope/docs.ui"}
             end)
    end

    test "return the Swagger UI page when calling /docs.ui" do
      conn = get("/api/some_scope/docs.ui")

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ "<title>Swagger UI</title>"
    end

    test "return the yaml spec when calling /docs.yaml" do
      conn = get("/api/some_scope/docs.yaml")
      refute conn.halted
      assert conn.status == 200
      # Expects the spec to begin with "openapi:"
      assert conn.resp_body =~ ~r/^openapi:/
    end

    test "return the json spec when calling /docs.json" do
      conn = get("/api/some_scope/docs.json")

      refute conn.halted
      assert conn.status == 200
      # Expects the spec to begin with "openapi:"
      assert conn.resp_body =~ ~r/^{\n  \"openapi\"/
    end

    test "redirect to docs.ui when calling an invalid swagger path" do
      conn = get("/api/some_scope/swagger/some_invalid_path/file.yaml")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/api/some_scope/docs.ui)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/api/some_scope/docs.ui"}
             end)
    end

    test "redirect to docs.ui when calling a file with an invalid extension" do
      conn = get("/api/some_scope/swagger/file.invalid")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/api/some_scope/docs.ui)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/api/some_scope/docs.ui"}
             end)
    end
  end

  describe "/errors endpoints" do
    test "redirect to /errors.ui when calling /errors" do
      conn = get("/api/some_scope/errors")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/api/some_scope/errors.ui)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/api/some_scope/errors.ui"}
             end)
    end

    test "returns the HTML page when calling /errors.ui" do
      conn = get("/api/some_scope/errors.ui")

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ ~r"<title>Error Codes for .*</title>"
    end

    test "returns the yaml spec when calling /errors.yaml" do
      conn = get("/api/some_scope/errors.yaml")

      refute conn.halted
      assert conn.status == 200
      # Expects the response to have a `code` key
      assert conn.resp_body =~ ~r/code:/
      # Expects the response to have a `description` key
      assert conn.resp_body =~ ~r/description:/
    end

    test "returns the json spec when calling /errors.json" do
      conn = get("/api/some_scope/errors.json")

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
    |> put_private(:phoenix_endpoint, EWalletAPI.Endpoint)
    |> TestRouter.call([])
  end
end
