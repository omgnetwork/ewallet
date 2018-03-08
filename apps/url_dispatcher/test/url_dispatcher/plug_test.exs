defmodule UrlDispatcher.PlugTest do
  use ExUnit.Case
  use Plug.Test
  alias UrlDispatcher.Plug

  defp request(path) do
    :get
    |> conn(path)
    |> Plug.call([])
  end

  describe "call/2" do
    test "returns success status when requesting /" do
      conn = request("/")

      refute conn.halted
      assert conn.status == 200
      assert conn.resp_body == ~s({"status":true})
    end

    test "returns a 200 response when requesting /api" do
      conn = request("/api")
      refute conn.halted
      assert conn.status == 200
    end

    test "returns a 200 response when requesting /admin/api" do
      conn = request("/admin/api")
      refute conn.halted
      assert conn.status == 200
    end

    test "returns a 404 response and halts when requesting an unknown endpoint" do
      conn = request("/unknown_endpoint")

      assert conn.halted
      assert conn.status == 404
      assert conn.resp_body == "The url could not be resolved."
    end

    test "returns a 200 response when requesting a file in /public folder" do
      conn = request("/public/uploads/robots.txt")

      assert conn.halted # Plug.Static returns `%Plug.Conn{halted: true}` on success
      assert conn.status == 200
    end

    test "returns a 404 response and halts when requesting an unknown file /public" do
      conn = request("/unknown_endpoint")

      assert conn.halted
      assert conn.status == 404
      assert conn.resp_body == "The url could not be resolved."
    end
  end
end
