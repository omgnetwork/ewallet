defmodule AdminAPI.V1.TransactionCalculationViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.TransactionCalculationView
  alias EWallet.Exchange.Calculation

  describe "render/2" do
    test "renders calculation.json with correct response structure" do
      pair = insert(:exchange_pair)

      calculation = %Calculation{
        from_amount: 1000,
        from_token: pair.from_token,
        to_amount: 2000,
        to_token: pair.to_token,
        actual_rate: pair.rate,
        pair: pair,
        calculated_at: NaiveDateTime.utc_now()
      }

      rendered =
        TransactionCalculationView.render("calculation.json", %{calculation: calculation})

      assert rendered.success == true
      assert rendered.data.object == "transaction_calculation"
    end
  end
end
