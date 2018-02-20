defmodule EWallet.Web.SwaggerPlugTest do
  use ExUnit.Case
  use Plug.Test
  alias EWallet.Web.SwaggerPlug

  describe "call/2" do
    test "returns the Swagger UI page when calling /" do
      conn =
        :get
        |> conn("/")
        |> SwaggerPlug.call([otp_app: :ewallet])

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ "<title>Swagger UI</title>"
    end

    test "returns the Swagger spec when calling /swagger.yaml" do
      conn =
        :get
        |> conn("/swagger.yaml")
        |> SwaggerPlug.call([otp_app: :admin_api])

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body =~ ~r/^openapi:/
    end

    test "returns 404 error when calling a path that does not exist" do
      conn =
        :get
        |> conn("/not_exists")
        |> SwaggerPlug.call([otp_app: :ewallet])

      assert conn.halted
      assert conn.status == 404
      assert conn.resp_body == "File not found."
    end
  end
end
