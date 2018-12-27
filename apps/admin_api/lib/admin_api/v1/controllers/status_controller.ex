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

defmodule AdminAPI.V1.StatusController do
  use AdminAPI, :controller

  def index(conn, _attrs) do
    json(conn, %{success: true})
  end

  @spec server_error(any(), any()) :: no_return()
  def server_error(_conn, _attrs) do
    raise "Mock server error"
  end
end
