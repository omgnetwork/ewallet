defmodule KuberaAPI.V1.FallbackControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "/not_found" do
    test "returns correct error response format and error message" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:endpoint_not_found",
          "description" => "Endpoint not found",
          "messages" => nil
        }
      }

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/not_found")
        |> json_response(:ok)

      assert response == expected
    end
  end
end
