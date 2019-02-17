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

defmodule EWalletDB.Repo.Seeds.CategorySampleSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Category}
  alias EWalletDB.Seeder

  @seed_data [
    %{name: "category1", description: "Sample Category 1", account_names: ["brand1", "branch1"], originator: %Seeder{}},
    %{name: "category2", description: "Sample Category 2", account_names: ["brand2", "branch2"], originator: %Seeder{}},
  ]

  def seed do
    [
      run_banner: "Seeding sample categories:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case Category.get_by(name: data.name) do
      nil ->
        case insert(data) do
          {:ok, category} ->
            category = Category.get(category.id)

            writer.success("""
              Name     : #{category.name}
              ID       : #{category.id}
              Accounts : #{get_account_names(category)}
            """)

          {:error, changeset} ->
            writer.error("  The category #{data.name} could not be inserted:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  The category #{data.name} could not be inserted:")
            writer.error("  Unknown error.")
        end

      %Category{} = category ->
        writer.warn("""
          Name     : #{category.name}
          ID       : #{category.id}
          Accounts : #{get_account_names(category)}
        """)
    end
  end

  defp insert(data) do
    case Category.insert(data) do
      {:ok, category} ->
        Enum.each(data.account_names, fn(name) ->
          [name: name]
          |> Account.get_by()
          |> Account.add_category(category, %Seeder{})
        end)
        {:ok, category}

      other_result ->
        other_result
    end
  end

  defp get_account_names(category) do
    {:ok, category} = Preloader.preload_one(category, :accounts)
    category
    |> Map.fetch!(:accounts)
    |> Enum.map(fn(a) -> a.name end)
    |> Enum.join(", ")
  end
end
