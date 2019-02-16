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

defmodule ActivityLogger.TestDocument do
  @moduledoc """
  Ecto Schema representing test documents.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  alias Ecto.UUID
  alias ActivityLogger.Repo

  alias ActivityLogger.TestDocument

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "test_document" do
    external_id(prefix: "tdc_")

    field(:title, :string)
    field(:body, :string)
    field(:secret_data, ActivityLogger.Encrypted.Map, default: %{})

    timestamps()
    activity_logging()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:title, :body, :secret_data],
      required: [:title],
      encrypted: [:secret_data],
      prevent_saving: [:body]
    )
  end

  @spec insert(map()) :: {:ok, %TestDocument{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %TestDocument{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log([])
  end
end
