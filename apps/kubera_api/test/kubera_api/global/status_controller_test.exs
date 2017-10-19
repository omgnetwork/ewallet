defmodule KuberaAPI.StatusControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "GET request to root url" do
    test "returns status ok" do

      response = build_conn()
        |> get("/")
        |> json_response(:ok)

      assert response == %{"success" => true}
    end
  end
end
