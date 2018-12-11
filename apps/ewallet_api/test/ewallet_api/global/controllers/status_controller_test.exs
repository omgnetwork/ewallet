defmodule EWalletAPI.StatusControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "GET request to root url" do
    test "returns status ok" do
      response =
        build_conn()
        |> get(@base_dir <> "/")
        |> json_response(:ok)

      assert response == %{
               "success" => true,
               "nodes" => 1,
               "services" => %{
                 "ewallet" => true,
                 "local_ledger" => true
               },
               "ewallet_version" => "1.1.0",
               "api_versions" => [
                 %{"name" => "v1", "media_type" => "application/vnd.omisego.v1+json"}
               ]
             }
    end
  end
end
