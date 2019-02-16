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

defmodule ActivityLogger.ActivityRepo do
  @moduledoc """
  Module meant to be used inside an Ecto.Repo module to add the
  functions generating activity logs.
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @repo opts[:repo]

      import Ecto.{Changeset, Query}
      alias ActivityLogger.ActivityLog
      alias Ecto.{Multi, Changeset}

      def __repo__ do
        @repo
      end

      @spec insert_record_with_activity_log(%Changeset{}, Keyword.t(), Multi.t()) ::
              {:ok, any()}
              | {:error, any()}
              | {:error, :no_originator_given}
              | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
      def insert_record_with_activity_log(changeset, opts \\ [], multi \\ Multi.new()) do
        :insert
        |> perform(changeset, opts, multi)
        |> handle_perform_result(:insert, changeset)
      end

      @spec update_record_with_activity_log(%Changeset{}, Keyword.t(), Multi.t()) ::
              {:ok, any()}
              | {:error, any()}
              | {:error, :no_originator_given}
              | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
      def update_record_with_activity_log(changeset, opts \\ [], multi \\ Multi.new()) do
        :update
        |> perform(changeset, opts, multi)
        |> handle_perform_result(:update, changeset)
      end

      @spec delete_record_with_activity_log(map(), Keyword.t(), Multi.t()) ::
              {:ok, any()}
              | {:error, any()}
              | {:error, :no_originator_given}
              | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
      def delete_record_with_activity_log(changeset, opts \\ [], multi \\ Multi.new()) do
        :delete
        |> perform(changeset, opts, multi)
        |> handle_perform_result(:delete, changeset)
      end

      @spec perform(atom(), %Changeset{}, Keyword.t(), Multi.t()) ::
              {:ok, any()}
              | {:error, any()}
              | {:error, :no_originator_given}
              | {:error, Multi.name(), any(), %{optional(Multi.name()) => any()}}
      def perform(action, changeset, opts \\ [], multi \\ Multi.new()) do
        Multi
        |> apply(action, [Multi.new(), :record, changeset, opts])
        |> Multi.append(multi)
        |> __repo__().transaction()
      end

      defp handle_perform_result({:ok, %{record: record}}, action, changeset) do
        {:ok, activity_log} = ActivityLog.insert(action, changeset, record)

        {:ok, record}
      end

      defp handle_perform_result(
             {:error, _failed_operation, changeset, _changes_so_far},
             _action,
             _changeset
           ) do
        {:error, changeset}
      end
    end
  end
end
