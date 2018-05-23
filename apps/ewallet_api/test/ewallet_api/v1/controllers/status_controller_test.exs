defmodule EWalletAPI.V1.StatusControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias Poison.Parser

  describe "/status" do
    test "returns success" do
      assert public_request("/status") == %{"success" => true}
    end
  end

  describe "/status.server_error" do
    test "returns correct error response format and error description" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "server:internal_server_error",
          "description" => "Mock server error",
          "messages" => nil
        }
      }

      # Note this test use a different approach to calling and asserting.
      # This is because a raised error get sent all the way up to the test
      # instead of being handled by Phoenix and return a response.
      #
      # See example: /phoenix/test/phoenix/endpoint/render_errors_test.exs
      {status, _headers, response} =
        assert_error_sent(500, fn ->
          public_request("/status.server_error")
        end)

      assert status == 500
      assert Parser.parse!(response) == expected
    end
  end
end
