# Script for populating the database.
#
## Usage
#
# You can run the seed through mix alias on the root umbrella app folder:
#
# ```
# mix seed
# ```
#
# Or run the seed directly:
#
# ```
# mix run apps/kubera_db/priv/repo/seeds.exs
# ```
#
# And run the seed with genesis (requires LocalLedger to be running):
#
# ```
# mix run apps/kubera_db/priv/repo/seeds.exs --with-genesis
# ```
#
# All mix aliases that runs the seed also automatically
# supports `--with-genesis` flag:
#
# ```
# mix init --with-genesis
# mix reset --with-genesis
# mix seed --with-genesis
# ```
#
## Naming convention
#
# To add more types of seeds, simply create a new seed file,
# then append the new file name to the `files` list below.
#
# Note that the numbered prefix is used to help group the context
# and/or visualize the dependencies.
#
# i.e. accounts --> other entities --> authentications
#
# Prefix increments by 10 in case new seeds need to be inserted in the middle.
# Try to name the seed file the same as the schema.
#
## Seeding script
#
# Inside each seed file, you can seed the entity by calling
# the schema's insert function:
#
# ```
# KuberaDB.SomeSchema.insert(a_data_map)
# ```
#
# Direct repo insert, e.g. `KuberaDB.Repo.insert!` should be avoided because
# it does not preserve data integrity implemented in the schema.

case Application.get_env(:kubera_db, :env) do
  :prod ->
    KuberaDB.CLI.halt("Seeder cannot be run on :prod environment!")
  _ ->
    nil
end

# Disable noisy debug messages. Seeders already have their own log messages.
Logger.configure(level: :warn)

# Seed by executing each file in `./seeders`
__DIR__ <> "/seeders"
|> File.ls!()
|> Enum.sort()
|> Enum.each(fn(file) -> Code.load_file(file, __DIR__ <> "/seeders") end)
