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

defmodule ActivityLogger.Repo.Migrations.AddTargetAndOriginatorIdentifierInActivityLog do
  use Ecto.Migration

  def change do
    alter table(:activity_log) do
      add :target_identifier, :string
      add :originator_identifier, :string
    end

    create index(:activity_log, [:target_identifier, :target_type])
    create index(:activity_log, [:originator_identifier, :originator_type])
  end
end
