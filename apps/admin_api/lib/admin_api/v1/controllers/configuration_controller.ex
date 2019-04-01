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
  alias EWallet.ConfigurationPolicy
  alias EWalletDB.Account
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
         {attrs, error} <- validate_master_account(attrs),
         {:ok, settings} <- Config.update(attrs),
         settings <- add_master_account_error(settings, error) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end

  defp validate_master_account(%{"master_account" => master_account_id} = attrs) do
    case Account.get(master_account_id) do
      nil ->
        {
          Map.delete(attrs, "master_account"),
          {:master_account, {:error, prepare_error(master_account_id)}}
        }

      _ ->
        {attrs, nil}
    end
  end

  defp validate_master_account(attrs), do: {attrs, nil}

  defp prepare_error(master_account_id) do
    %StoredSetting{}
    |> Changeset.change(%{value: master_account_id})
    |> Changeset.add_error(:value, "must match an existing account",
      validation: :account_not_found
    )
  end

  defp add_master_account_error(settings, nil) do
    settings
  end

  defp add_master_account_error(settings, master_account_setting_error) do
    [master_account_setting_error | settings]
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
