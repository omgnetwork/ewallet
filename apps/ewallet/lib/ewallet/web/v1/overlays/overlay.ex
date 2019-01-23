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

defmodule EWallet.Web.V1.Overlay do
  @moduledoc """
  Behavior definition for overlays.
  """

  # The fields that can be used as `page_record_field`.
  @callback pagination_fields() :: [Atom.t()]

  # The fields that can be preloaded.
  @callback preload_assocs() :: [Atom.t()]

  # The fields that should always be preloaded.
  # Note that these values *must be in the schema associations*.
  @callback default_preload_assocs() :: [Atom.t()]

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  @callback search_fields() :: [Atom.t()]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  @callback sort_fields() :: [Atom.t()]

  # The fields that are allowed to be filtered.
  @callback self_filter_fields() :: [Atom.t()]
  @callback filter_fields() :: [Atom.t()]
end
