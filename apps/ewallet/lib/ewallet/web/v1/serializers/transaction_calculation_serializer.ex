defmodule EWallet.Web.V1.TransactionCalculationSerializer do
  @moduledoc """
  Serializes a transaction calculation into V1 JSON response format.
  """
  alias EWallet.Exchange.Calculation
  alias EWallet.Web.Date
  alias EWallet.Web.V1.ExchangePairSerializer

  def serialize(%Calculation{} = calculation) do
    %{
      object: "transaction_calculation",
      from_amount: calculation.from_amount,
      from_token_id: calculation.from_token.id,
      to_amount: calculation.to_amount,
      to_token_id: calculation.to_token.id,
      actual_rate: calculation.actual_rate,
      exchange_pair: ExchangePairSerializer.serialize(calculation.pair),
      calculated_at: Date.to_iso8601(calculation.calculated_at)
    }
  end

  def serialize(nil), do: nil
end
