defmodule EWallet.Exchange.Calculation do
  @moduledoc """
  Represents an exchange calculation.
  """
  alias EWalletDB.{ExchangePair, Token}

  @enforce_keys [
    :from_amount,
    :from_token,
    :to_amount,
    :to_token,
    :actual_rate,
    :pair,
    :calculated_at
  ]
  defstruct [
    :from_amount,
    :from_token,
    :to_amount,
    :to_token,
    :actual_rate,
    :pair,
    :calculated_at
  ]

  @type t :: %__MODULE__{
          from_amount: non_neg_integer(),
          from_token: %Token{},
          to_amount: non_neg_integer(),
          to_token: %Token{},
          actual_rate: float(),
          pair: %ExchangePair{},
          calculated_at: NaiveDateTime.t()
        }
end
