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

defmodule EWallet.Case do
  @moduledoc """
  A test case template for all tests.
  """
  use ExUnit.CaseTemplate

  @temp_test_file_dir "private/temp_test_files"

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWallet.Case

      setup do
        # Create the directory to store the temporary test files
        :ok = File.mkdir_p!(test_file_path())
      end
    end
  end

  def test_file_path do
    :ewallet
    |> Application.get_env(:root)
    |> Path.join(@temp_test_file_dir)
  end

  def test_file_path(file_name) do
    Path.join(test_file_path(), file_name)
  end

  def is_url?(url) do
    String.starts_with?(url, "https://") || String.starts_with?(url, "http://")
  end
end
