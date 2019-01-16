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

defmodule EWalletDB.Uploaders.AvatarTest do
  use ExUnit.Case, async: true
  alias Arc.File
  alias EWalletDB.Account
  alias EWalletDB.Uploaders.Avatar

  describe "validate/1" do
    test "returns true if the file name ends with .jpg" do
      assert Avatar.validate({%File{file_name: "some_file.jpg"}, nil})
    end

    test "returns true if the file name ends with .jpeg" do
      assert Avatar.validate({%File{file_name: "some_file.jpeg"}, nil})
    end

    test "returns true if the file name ends with .gif" do
      assert Avatar.validate({%File{file_name: "some_file.gif"}, nil})
    end

    test "returns true if the file name ends with .png" do
      assert Avatar.validate({%File{file_name: "some_file.png"}, nil})
    end

    test "returns false if the file name ends with an unsupported extension" do
      refute Avatar.validate({%File{file_name: "some_file.zip"}, nil})
      refute Avatar.validate({%File{file_name: "some_file.exe"}, nil})
      refute Avatar.validate({%File{file_name: "some_file.txt"}, nil})
      refute Avatar.validate({%File{file_name: "some_file.csv"}, nil})
    end
  end

  describe "transform/2" do
    test "returns the png conversion argument command for :large" do
      {operation, args, type} = Avatar.transform(:large, {%File{}, nil})

      assert operation == :convert
      assert String.contains?(args, " -extent 400x400")
      assert String.contains?(args, " -format png")
      assert type == :png
    end

    test "returns the png conversion argument command for :small" do
      {operation, args, type} = Avatar.transform(:small, {%File{}, nil})

      assert operation == :convert
      assert String.contains?(args, " -extent 150x150")
      assert String.contains?(args, " -format png")
      assert type == :png
    end

    test "returns the png conversion argument command for :thumb" do
      {operation, args, type} = Avatar.transform(:thumb, {%File{}, nil})

      assert operation == :convert
      assert String.contains?(args, " -extent 50x50")
      assert String.contains?(args, " -format png")
      assert type == :png
    end
  end

  describe "filename/2" do
    test "returns the given version" do
      assert Avatar.filename("v1", {%File{}, nil}) == "v1"
    end
  end

  describe "storage_dir/2" do
    test "returns a public path categorized by the schema" do
      path = Avatar.storage_dir("some_version", {%File{}, %Account{id: "some_account_id"}})

      assert ["public", "uploads", _, "account", "avatars", "some_account_id"] = Path.split(path)
    end
  end
end
