defmodule KuberaAPI.V1.StatusControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1
  alias Poison.Parser

  describe "/status" do
    test "returns success" do

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/status")
        |> json_response(:ok)

      assert response == %{"success" => true}
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
        assert_error_sent 500, fn ->
          build_conn()
          |> put_req_header("accept", @header_accept)
          |> post("/status.server_error")
        end

      assert status == 500
      assert Parser.parse!(response) == expected
    end
  end
end
