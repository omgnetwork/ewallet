# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
