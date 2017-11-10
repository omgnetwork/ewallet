defmodule Kubera.Transactions.Formatter do
  @moduledoc """
  Handles the formatting of the transaction that is suitable for caishen
  """
  def format(from, to, minted_token, amount, metadata) do
    %{
      from: from,
      to: to,
      minted_token: minted_token,
      amount: amount,
      metadata: metadata
    }
  end
end
