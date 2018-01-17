defmodule EWalletAPI.StatusControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "GET request to root url" do
    test "returns status ok" do

      response = build_conn()
        |> get("/")
        |> json_response(:ok)

      assert response == %{
        "success" => true,
        "services" => %{
          "ewallet" => true,
          "local_ledger" => true
        }
      }
    end
  end
end
