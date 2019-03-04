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

defmodule EWallet.Web.V1.BalanceSerializer do
  @moduledoc """
  Serializes wallet data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{TokenSerializer, PaginatorSerializer}
  alias EWallet.Web.{Paginator, BalanceLoader}

  # Both the given wallet and `%NotLoaded{}` are maps
  # so we need to pattern-match `%NotLoaded{}` first.
  def serialize(%NotLoaded{}), do: nil

  def serialize(%{amount: amount, token: token}) do
    %{
      amount: amount,
      token: TokenSerializer.serialize(token),
      object: "balance"
    }
  end

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(nil), do: nil
end
