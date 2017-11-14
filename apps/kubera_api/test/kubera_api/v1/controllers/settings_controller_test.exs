defmodule KuberaAPI.V1.SettingsControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "/get_settings" do
    test "responds with a list of minted_tokens" do
      response =
        build_conn()
        |> put_req_header("accept", @header_accept)
        |> put_req_header("authorization", @header_auth)
        |> post("/get_settings", %{})
        |> json_response(:ok)

      assert response["success"]
      assert Map.has_key?(response["data"], "minted_tokens")
      assert is_list(response["data"]["minted_tokens"])
    end
  end
end
