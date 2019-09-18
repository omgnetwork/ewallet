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

defmodule AdminAPI.V1.ConfigurationController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler

  alias EWallet.Web.{Orchestrator, Originator, V1.ConfigurationOverlay}
  alias EWalletConfig.{Config, Repo, StoredSetting}
  alias EWallet.{BlockchainHelper, ConfigurationPolicy}
  alias EWalletDB.{Account, BlockchainWallet}
  alias Ecto.Changeset

  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns),
         true <- !is_nil(query) || {:error, :unauthorized} do
      settings =
        query
        |> Orchestrator.build_query(ConfigurationOverlay, attrs)
        |> Repo.all()

      render(conn, :settings, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  def update(conn, attrs) do
    with {:ok, _} <- authorize(:update, conn.assigns),
         attrs <- put_originator(conn, attrs),
         {attrs, errors} <- validate(attrs),
         {:ok, settings} <- Config.update(attrs),
         settings <- add_errors(settings, errors) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  defp validate(attrs) do
    {attrs, []}
    |> validate_master_account()
    |> validate_primary_hot_wallet()
  end

  defp validate_master_account({%{"master_account" => master_account_id} = attrs, errors}) do
    case Account.get(master_account_id) do
      nil ->
        {
          Map.delete(attrs, "master_account"),
          [{:master_account, {:error, prepare_account_error(master_account_id)}} | errors]
        }

      _ ->
        {attrs, errors}
    end
  end

  defp validate_master_account(attrs), do: attrs

  defp validate_primary_hot_wallet(
         {%{"primary_hot_wallet" => primary_hot_wallet_address} = attrs, errors}
       ) do
    identifier = BlockchainHelper.rootchain_identifier()

    case BlockchainWallet.get(primary_hot_wallet_address, "hot", identifier) do
      nil ->
        {
          Map.delete(attrs, "primary_hot_wallet"),
          [
            {:primary_hot_wallet, {:error, prepare_hot_wallet_error(primary_hot_wallet_address)}}
            | errors
          ]
        }

      _ ->
        {attrs, errors}
    end
  end

  defp validate_primary_hot_wallet(attrs), do: attrs

  defp prepare_hot_wallet_error(primary_hot_wallet_address) do
    prepare_error(
      primary_hot_wallet_address,
      "must match an existing hot wallet",
      :hot_wallet_not_found
    )
  end

  defp prepare_account_error(master_account_id) do
    prepare_error(master_account_id, "must match an existing account", :account_not_found)
  end

  defp prepare_error(field, description, validation) do
    %StoredSetting{}
    |> Changeset.change(%{value: field})
    |> Changeset.add_error(:value, description, validation: validation)
  end

  defp add_errors(settings, []) do
    settings
  end

  defp add_errors(settings, errors) do
    errors ++ settings
  end

  defp put_originator(conn, attrs) when is_list(attrs) do
    originator = Originator.extract(conn.assigns)

    case Keyword.keyword?(attrs) do
      true ->
        [{:originator, originator} | attrs]

      false ->
        Enum.map(attrs, fn setting_map ->
          Map.put(setting_map, :originator, originator)
        end)
    end
  end

  defp put_originator(conn, attrs) when is_map(attrs) do
    Map.put(attrs, :originator, Originator.extract(conn.assigns))
  end

  @spec authorize(:get | :update, map()) :: any()
  defp authorize(action, actor) do
    ConfigurationPolicy.authorize(action, actor, nil)
  end
end
