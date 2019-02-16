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

defmodule EWalletAPI.V1.SelfController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.{Orchestrator, V1.WalletOverlay}
  alias EWallet.BalanceFetcher
  alias EWalletDB.Token

  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.end_user})
  end

  def get_settings(conn, _attrs) do
    settings = %{tokens: Token.all()}
    render(conn, :settings, settings)
  end

  def get_wallets(conn, attrs) do
    with {:ok, wallet} <- BalanceFetcher.all(%{"user_id" => conn.assigns.end_user.id}) do
      {:ok, wallets} = Orchestrator.all([wallet], WalletOverlay, attrs)
      render(conn, :wallets, %{wallets: wallets})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end
end
