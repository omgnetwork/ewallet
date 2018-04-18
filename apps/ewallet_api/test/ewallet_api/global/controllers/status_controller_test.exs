defmodule EWalletAPI.StatusControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "GET request to root url" do
    test "returns status ok" do

      response = build_conn()
        |> get(@base_dir <> "/")
        |> json_response(:ok)

      assert response == %{
        "success" => true,
        "nodes" => 1,
        "services" => %{
          "ewallet" => true,
          "local_ledger" => true
        }
      }
    end
  end
end
