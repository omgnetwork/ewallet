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

defmodule EWalletDB.Helpers.Preloader do
  @moduledoc """
  A helper module that helps with preloading records.
  """
  alias EWalletDB.Repo

  @doc """
  Takes the provided `:preload` option (if any) and preloads those associations.
  """
  def preload_option(records, opts) do
    case opts[:preload] do
      nil -> records
      preload -> Repo.preload(records, preload)
    end
  end

  @doc """
  Preloads the given struct with the given associations.

  This function simply calls `Repo.preload/2` but is useful for
  abstracting away the `Repo` module from non-DB callers.
  """
  def preload(struct, assocs) do
    Repo.preload(struct, assocs)
  end
end
