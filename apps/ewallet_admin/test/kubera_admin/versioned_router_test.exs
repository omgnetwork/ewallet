defmodule EWalletAdmin.VersionedRouterTest do
  use EWalletAdmin.ConnCase, async: true

  # Potential candidate to be moved to a shared library
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  describe "versioned router" do
    test "accepts v1+json requests" do
      response = build_conn()
      |> put_req_header("accept", "application/vnd.omisego.v1+json")
      |> put_auth_header("OMGAdmin", [@api_key_id, @api_key])
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
