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

defmodule LocalLedger.EctoBatchStream do
  @moduledoc """
  This module is can be used to batch stream records from database and avoid overflowing with
  millions of records. The default is 1000 records / batch.
  """
  import Ecto.Query, only: [from: 2]

  @batch_size 1000

  # Example:
  #
  #     query = from u in MyApp.User, select: u.email
  #     stream = EctoBatchStream.stream(MyApp.Repo, query)
  #     stream |> Stream.take(3) |> Enum.to_list # => […]
  def stream(repo, query, batch_size \\ @batch_size) do
    batches_stream =
      Stream.unfold(0, fn
        :done ->
          nil

        offset ->
          results = repo.all(from(_ in query, offset: ^offset, limit: ^batch_size))

          if length(results) < batch_size,
            do: {results, :done},
            else: {results, offset + batch_size}
      end)

    batches_stream |> Stream.concat()
  end
end
