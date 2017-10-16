defmodule KuberaAPI.V1.StatusControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "/status" do
    test "returns success" do

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/status")
        |> json_response(:ok)

      assert response == %{"success" => true}
    end
  end
end
