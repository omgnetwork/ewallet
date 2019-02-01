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
  alias EWallet.Helper
  alias EWalletConfig.Config
  alias EWalletConfig.Storage.Local
  alias Ecto.UUID

  setup do
    root = Helper.static_dir(:url_dispatcher)
    uuid = UUID.generate()
    path = Path.join(["private", uuid])
    path_abs = Path.join([root, path])

    :ok = File.mkdir_p!(path_abs)

    Code.eval_string("""
      defmodule MockDefinition do
        use Arc.Definition
        def storage_dir(_, _) do
          #{Macro.to_string(path)}
        end
      end
    """)

    on_exit(fn ->
      :code.purge(MockDefinition)
      :code.delete(MockDefinition)

      _ = File.rm_rf!(path_abs)
    end)

    %{root: root, uuid: uuid, path: path, path_abs: path_abs, mockdef: MockDefinition}
  end

  describe "get_path/2" do
    test "returns the path with the root dir prepended", context do
      root_dir = context.root
      destination_dir = "some_dir/another_dir"
      file_name = "some_filename.txt"

      path = Local.get_path(destination_dir, file_name)

      assert path == "#{root_dir}/#{destination_dir}/#{file_name}"
    end
  end

  describe "put/3" do
    test "save to file from binary data and returns the file name", context do
      # Prepare the data
      binary = "some_data_to_save"

      file = %Arc.File{
        file_name: "test-#{:rand.uniform(999_999)}.txt",
        binary: binary
      }

      # Invoke & assert
      {res, file_name} = Local.put(context.mockdef, "v1", {file, nil})
      assert res == :ok
      assert file_name == file.file_name
    end

    test "save to file from a path and returns the file name", context do
      # Prepare the data
      source_path =
        nil
        |> context.mockdef.storage_dir(nil)
        |> Local.get_path("test-source-#{:rand.uniform(999_999)}.txt")

      file = %Arc.File{
        file_name: "test-#{:rand.uniform(999_999)}.txt",
        path: source_path
      }

      # Create the source file
      :ok = File.write(source_path, "some_content_to_copy")

      # Invoke & assert
      {res, file_name} = Local.put(context.mockdef, "v1", {file, nil})
      assert res == :ok
      assert file_name == file.file_name
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

      # Need to append / to the context.uuid otherwise URI.merge will treat
      # it as file and never gets included in the final URL.
      expected =
        context.base_url
        |> URI.merge(context.mockdef.storage_dir(nil, nil))
        |> URI.merge("#{context.uuid}/")
        |> URI.merge(file.file_name)
        |> URI.to_string()

      assert Local.url(context.mockdef, "v1", {file, nil}) == expected
    end
  end

  describe "delete/3" do
    test "deletes the given file", context do
      file = %Arc.File{
        file_name: "test-#{:rand.uniform(999_999)}.txt",
        binary: "this file should be deleted soon"
      }

      # Create the file to be deleted
      {:ok, _} = Local.put(context.mockdef, "v1", {file, nil})

      # Invoke & assert
      assert Local.delete(context.mockdef, "v1", {file, nil}) == :ok
    end
  end
end
