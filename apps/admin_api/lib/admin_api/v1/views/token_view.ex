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

defmodule AdminAPI.V1.TokenView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, TokenSerializer, TokenStatsSerializer}

  def render("token.json", %{token: token}) do
    token
    |> TokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("tokens.json", %{tokens: tokens}) do
    tokens
    |> TokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("stats.json", %{stats: stats}) do
    stats
    |> TokenStatsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
