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

defmodule AdminAPI.V1.AccountScopePlug do
  @moduledoc """
  This plug extracts the account's scope from the request header,
  and assigns it to the connection as `scoped_account_id` for downstream usage.
  """
  import Plug.Conn
  import AdminAPI.V1.ErrorHandler
  alias Ecto.UUID

  def init(opts), do: opts

  def call(conn, _opts) do
    parse_header(conn)
  end

  defp parse_header(conn) do
    header =
      conn
      |> get_req_header("omgadmin-account-id")
      |> List.first()

    with header when not is_nil(header) <- header,
         {:ok, uuid} when is_binary(uuid) <- UUID.cast(header) do
      assign(conn, :scoped_account_id, uuid)
    else
      # If the header is provided, it must be a UUID
      :error ->
        handle_error(conn, :invalid_account_id)

      # If the header is not provided, this plug does nothing
      nil ->
        conn
    end
  end
end
