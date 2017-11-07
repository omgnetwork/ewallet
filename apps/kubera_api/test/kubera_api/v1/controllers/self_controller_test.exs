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

  describe "/me.get_settings" do
    test "responds with a list of minted_tokens" do
      api_key     = insert(:api_key).key
      auth_token  = insert(:auth_token).token

      response =
        build_conn()
        |> put_req_header("accept", @header_accept)
        |> put_auth_header("OMGClient", api_key, auth_token)
        |> post("/me.get_settings", %{})
        |> json_response(:ok)

      assert response["success"]
      assert Map.has_key?(response["data"], "minted_tokens")
      assert is_list(response["data"]["minted_tokens"])
    end
  end
end
