defmodule KuberaAPI.V1.SelfControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "/me.get" do
    test "responds with user data" do
      api_key     = insert(:api_key).key
      user        = insert(:user)
      auth_token  = insert(:auth_token, %{user: user}).token

      response =
        build_conn()
        |> put_req_header("accept", @header_accept)
        |> put_auth_header("OMGClient", api_key, auth_token)
        |> post("/me.get", %{})
        |> json_response(:ok)

      assert response["success"]
      assert response["data"]["id"] == user.id
    end
  end
end
