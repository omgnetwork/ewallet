# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule Utils.Ledgers.WalletSchema do
  @moduledoc """
  Defines common behaviours for ledger wallet schemas.
  """

  @callback all([String.t()]) :: [Ecto.Schema.t()]
  @callback get(String.t()) :: Ecto.Schema.t() | nil
  @callback get_by(Keyword.t() | map()) :: Ecto.Schema.t() | nil
  @callback get_or_insert(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback insert(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback touch([String.t()]) :: {integer(), nil | [term()]}
end
