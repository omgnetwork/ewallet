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

defmodule EWalletDB.Uploaders.FileTest do
  use ExUnit.Case, async: true
  alias Arc.File
  alias EWalletDB.Uploaders.File

  describe "validate/1" do
    test "returns true if the file name ends with .csv" do
      assert File.validate({%Arc.File{file_name: "some_file.csv"}, nil})
    end

    test "returns false if the file name does not end with .csv" do
      refute File.validate({%Arc.File{file_name: "some_file.zip"}, nil})
      refute File.validate({%Arc.File{file_name: "some_file.exe"}, nil})
      refute File.validate({%Arc.File{file_name: "some_file.txt"}, nil})
      refute File.validate({%Arc.File{file_name: "some_file.jpg"}, nil})
    end
  end

  describe "storage_dir/2" do
    test "returns a path under private/uploads/_/exports" do
      path = File.storage_dir(nil, nil)
      assert ["private", "uploads", _, "exports"] = Path.split(path)
    end
  end
end
