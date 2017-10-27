defmodule KuberaAPI.VersionedRouterTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "versioned router" do
    test "accepts v1+json requests" do
      response = build_conn()
      |> put_req_header("accept", @header_accept)
      |> post("/status")
      |> json_response(:ok)

      assert response == %{"success" => :true}
    end

    test "rejects unrecognized version requests" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_version",
          "description" => "Invalid API version. Given: \"application/vnd.omisego.invalid_ver+json\".",
          "messages" => nil
        }
      }

      response = build_conn()
      |> put_req_header("accept", "application/vnd.omisego.invalid_ver+json")
      |> post("/status")
      |> json_response(:ok)

      assert response == expected
    end
  end
end
