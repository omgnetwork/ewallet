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

defmodule EWalletConfig.Storage.LocalTest do
  use EWalletConfig.SchemaCase
  alias ActivityLogger.System
  alias EWalletConfig.Config
  alias EWalletConfig.Storage.Local

  defmodule MockDefinition do
    use Arc.Definition
    def storage_dir(_, _), do: "private/temp_test_files/"
  end

  setup do
    # Create the directory to store the temporary test files
    :ok = File.mkdir_p!(test_file_path())

    :ok
  end

  describe "get_path/2" do
    test "returns the path with the root dir prepended" do
      root_dir = Application.get_env(:ewallet, :root)
      destination_dir = "some_dir/another_dir"
      file_name = "some_filename.txt"

      path = Local.get_path(destination_dir, file_name)

      assert path == "#{root_dir}/#{destination_dir}/#{file_name}"
    end
  end

  describe "put/3" do
    test "save to file from binary data and returns the file name" do
      # Prepare the data
      binary = "some_data_to_save"

      file = %Arc.File{
        file_name: "test-#{:rand.uniform(999_999)}.txt",
        binary: binary
      }

      # Invoke & assert
      {res, file_name} = Local.put(MockDefinition, "v1", {file, nil})
      assert res == :ok
      assert file_name == file.file_name

      # Clean up the file after testing
      :ok =
        nil
        |> MockDefinition.storage_dir(nil)
        |> Local.get_path(file.file_name)
        |> File.rm()
    end

    test "save to file from a path and returns the file name" do
      # Prepare the data
      source_path =
        nil
        |> MockDefinition.storage_dir(nil)
        |> Local.get_path("test-source-#{:rand.uniform(999_999)}.txt")

      file = %Arc.File{
        file_name: "test-#{:rand.uniform(999_999)}.txt",
        path: source_path
      }

      # Create the source file
      :ok = File.write(source_path, "some_content_to_copy")

      # Invoke & assert
      {res, file_name} = Local.put(MockDefinition, "v1", {file, nil})
      assert res == :ok
      assert file_name == file.file_name

      # Clean up the file after testing
      :ok = File.rm(source_path)

      :ok =
        nil
        |> MockDefinition.storage_dir(nil)
        |> Local.get_path(file.file_name)
        |> File.rm()
    end
  end

  describe "url/4" do
    setup do
      base_url = "https://www.example.com"

      {:ok, _} =
        Config.insert(%{
          key: "base_url",
          value: base_url,
          type: "string",
          originator: %System{}
        })

      %{base_url: base_url}
    end

    test "returns a url for the given file", context do
      file = %Arc.File{file_name: "test-#{:rand.uniform(999_999)}.txt"}

      expected =
        context.base_url
        |> URI.merge(MockDefinition.storage_dir(nil, nil))
        |> URI.merge(file.file_name)
        |> URI.to_string()

      assert Local.url(MockDefinition, "v1", {file, nil}) == expected
    end
  end

  describe "delete/3" do
    test "deletes the given file" do
      file = %Arc.File{
        file_name: "test-#{:rand.uniform(999_999)}.txt",
        binary: "this file should be deleted soon"
      }

      # Create the file to be deleted
      {:ok, _} = Local.put(MockDefinition, "v1", {file, nil})

      # Invoke & assert
      assert Local.delete(MockDefinition, "v1", {file, nil}) == :ok
    end
  end

  defp test_file_path do
    :ewallet
    |> Application.get_env(:root)
    |> Path.join(@temp_test_file_dir)
  end
end
