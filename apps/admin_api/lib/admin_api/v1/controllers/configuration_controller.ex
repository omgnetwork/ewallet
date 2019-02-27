# Copyright 2018 OmiseGO Pte Ltd
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
  alias EWalletConfig.{Config, Repo}
  alias EWallet.ConfigurationPolicy

  def all(conn, attrs) do
    with {:ok, %{query: query}} <- authorize(:all, conn.assigns),
          true <- !is_nil(query) || {:error, :unauthorized} do
      settings =
        Config.query_settings()
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
         {:ok, settings} <- Config.update(attrs) do
      render(conn, :settings_with_errors, %{settings: settings})
    else
      {:error, code} -> handle_error(conn, code)
    end
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
