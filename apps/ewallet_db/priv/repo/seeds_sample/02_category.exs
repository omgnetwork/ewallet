defmodule EWalletDB.Repo.Seeds.CategorySampleSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Category}

  @seed_data [
    %{name: "category1", description: "Sample Category 1", account_names: ["brand1", "branch1"]},
    %{name: "category2", description: "Sample Category 2", account_names: ["brand2", "branch2"]},
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
          |> Account.add_category(category)
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
