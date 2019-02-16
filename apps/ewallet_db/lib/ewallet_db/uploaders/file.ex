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

defmodule EWalletDB.Uploaders.File do
  @moduledoc """
  Uploads an avatar after renaming it and transforming it.
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @acl :private
  @versions [:original]

  def validate({file, _}) do
    ~w(.csv) |> Enum.member?(Path.extname(file.file_name))
  end

  # Override the storage directory:
  def storage_dir(_, _) do
    "private/uploads/#{Application.get_env(:ewallet_db, :env)}/exports"
  end
end
