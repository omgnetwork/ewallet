# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.TokenStatsSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """
  alias EWallet.Web.V1.TokenSerializer

  def serialize(nil), do: nil

  def serialize(stats) do
    %{
      object: "token_stats",
      token_id: stats.token.id,
      token: TokenSerializer.serialize(stats.token),
      total_supply: stats.total_supply
    }
  end
end
