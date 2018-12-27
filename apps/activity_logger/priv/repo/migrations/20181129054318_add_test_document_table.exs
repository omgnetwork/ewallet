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

defmodule ActivityLogger.Repo.Migrations.AddTestDocumentTable do
  use Ecto.Migration

  def change do
    if Mix.env == :test do
      create table(:test_document, primary_key: false) do
        add :uuid, :uuid, primary_key: true
        add :id, :string, null: false
        add :title, :string
        add :body, :string
        add :secret_data, :binary

        timestamps()
      end
    end
  end
end
