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
      response = build_conn()
      |> put_req_header("accept", "application/vnd.omisego.invalid_ver+json")
      |> post("/")
      |> json_response(:bad_request)

      expected = %{
        "version" => @expected_version,
        "success" => :false,
        "data" => %{
          "object" => "error",
          "code" => "invalid_request_version",
          "message" => "Invalid request version. Given \"application/vnd.omisego.invalid_ver+json\"."
        }
      }

      assert response == expected
    end
  end
end
