defmodule EWalletConfig.Setting do
  @moduledoc """
  Schema overlay acting as an interface to the StoredSetting schema.
  This is needed because some transformation is applied to the
  attributes before saving them to the database. Indeed, value is stored
  in a map to allow any type to be saved, but is for simplicity, the
  users never need to know that - all they need to care is the "value"
  field.
  """
  import Ecto.Query
  alias EWalletConfig.{Repo, StoredSetting, Setting}
  alias Ecto.Changeset

  @split_char ":|:"
  @default_settings %{
    # Global Settings
    "base_url" => %{key: "base_url", value: "", type: "string"},
    "redirect_url_prefixes" => %{key: "redirect_url_prefixes", value: [], type: "array"},
    "enable_standalone" => %{
      key: "enable_standalone",
      value: false,
      type: "boolean",
      description:
        "Enables the /user.signup endpoint in the client API, allowing users to sign up directly."
    },
    "max_per_page" => %{
      key: "max_per_page",
      value: 100,
      type: "integer",
      description: "The maximum number of records that can be returned for a list."
    },
    "min_password_length" => %{
      key: "min_password_length",
      value: 8,
      type: "integer",
      description: "The minimum length for passwords."
    },
    # Email Settings
    "sender_email" => %{
      key: "sender_email",
      value: "admin@localhost",
      type: "string",
      description: "The address from which system emails will be sent."
    },
    "email_adapter" => %{
      key: "email_adapter",
      value: false,
      type: "select",
      options: ["smtp", "local", "test"],
      description: "When set to local, a local email adapter will be used. Perfect for testing and development.",
    },
    "smtp_host" => %{
      key: "smtp_host",
      value: nil,
      type: "string",
      description: "The SMTP host to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_port" => %{
      key: "smtp_port",
      value: nil,
      type: "string",
      description: "The SMTP port to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_username" => %{
      key: "smtp_username",
      value: nil,
      type: "string",
      description: "The SMTP username to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },
    "smtp_password" => %{
      key: "smtp_password",
      value: nil,
      type: "string",
      description: "The SMTP password to use to send emails.",
      parent: "email_adapter",
      parent_value: "smtp"
    },

    # Balance Caching Settings
    "balance_caching_strategy" => %{
      key: "balance_caching_strategy",
      value: "since_beginning",
      type: "select",
      options: ["since_beginning", "since_last_cached"],
      description:
        "The strategy to use for balance caching. It will either re-calculate from the beginning or from the last caching point."
    },

    # File Storage settings
    "file_storage_adapter" => %{
      key: "file_storage_adapter",
      value: "local",
      type: "select",
      options: ["local", "gcs", "aws"],
      description: "The type of storage to use for images and files."
    },

    # File Storage: GCS Settings
    "gcs_bucket" => %{
      key: "gcs_bucket",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The name of the GCS bucket."
    },
    "gcs_credentials" => %{
      key: "gcs_credentials",
      value: nil,
      secret: "true",
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "gcs",
      description: "The credentials of the Google Cloud account."
    },

    # File Storage: AWS Settings
    "aws_bucket" => %{
      key: "aws_bucket",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The name of the AWS bucket."
    },
    "aws_region" => %{
      key: "aws_region",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "The AWS region where your bucket lives."
    },
    "aws_access_key_id" => %{
      key: "aws_access_key_id",
      value: nil,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS access key having access to the specified bucket."
    },
    "aws_secret_access_key" => %{
      key: "aws_secret_access_key",
      value: nil,
      secret: true,
      type: "string",
      parent: "file_storage_adapter",
      parent_value: "aws",
      description: "An AWS secret having access to the specified bucket."
    }
  }

  defstruct [
    :uuid,
    :id,
    :key,
    :value,
    :type,
    :description,
    :options,
    :parent,
    :parent_value,
    :secret,
    :position,
    :inserted_at,
    :updated_at
  ]

  @spec get_default_settings() :: [Map.t()]
  def get_default_settings, do: @default_settings

  @spec types() :: [String.t()]
  def types, do: StoredSetting.types()

  @doc """
  Retrieves all settings.
  """
  @spec all() :: [%Setting{}]
  def all do
    StoredSetting
    |> order_by(asc: :position)
    |> Repo.all()
    |> Enum.map(&build/1)
  end

  @doc """
  Retrieves a setting by its string name.
  """
  @spec get(String.t()) :: %Setting{}
  def get(key) when is_binary(key) do
    case Repo.get_by(StoredSetting, key: key) do
      nil -> nil
      stored_setting -> build(stored_setting)
    end
  end

  def get(_), do: nil

  @spec get(String.t()) :: any()
  def get_value(key, default \\ nil)

  def get_value(key, default) when is_binary(key) do
    case Repo.get_by(StoredSetting, key: key) do
      nil -> default
      stored_setting -> stored_setting.data["value"]
    end
  end

  def get_value(nil, _), do: nil

  @doc """
  Creates a new setting with the passed attributes.
  """
  @spec insert(Map.t()) :: {:ok, %Setting{}} | {:error, %Changeset{}}
  def insert(attrs) do
    attrs = cast_attrs(attrs)

    %StoredSetting{}
    |> StoredSetting.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, stored_setting} ->
        {:ok, build(stored_setting)}

      {:error, changeset} ->
        {:error, build_changeset(changeset)}
    end
  end

  @doc """
  Inserts all the default settings.
  """
  @spec insert_all_defaults(Map.t()) :: [{:ok, %Setting{}}] | [{:error, %Changeset{}}]
  def insert_all_defaults(overrides) do
    @default_settings
    |> Enum.map(fn {key, data} ->
      case overrides[key] do
        nil ->
          insert(data)

        override ->
          data
          |> Map.put(:value, override)
          |> insert()
      end
    end)
    |> Enum.all?(fn res ->
      case res do
        {:ok, _} -> true
        _ ->        false
      end
    end)
    |> return_insert_result()
  end

  defp return_insert_result(true), do: :ok
  defp return_insert_result(false), do: :error

  def update(key, attrs) when is_binary(key) and is_map(attrs) do
    case Repo.get_by(StoredSetting, %{key: key}) do
      nil ->
        {:error, :setting_not_found}

      setting ->
        attrs = cast_attrs(attrs)

        setting
        |> StoredSetting.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, stored_setting} ->
            # Reload

            {:ok, build(stored_setting)}

          {:error, changeset} ->
            {:error, build_changeset(changeset)}
        end
    end
  end

  # TODO
  # def update_all(attrs) when is_map(attrs) do
  #   case Repo.get_by(StoredSetting, %{key: key}) do
  #     nil ->
  #       {:error, :setting_not_found}
  #
  #     setting ->
  #       attrs = cast_attrs(attrs)
  #
  #       setting
  #       |> StoredSetting.changeset(attrs)
  #       |> Repo.update()
  #       |> case do
  #         {:ok, stored_setting} ->
  #           {:ok, build(stored_setting)}
  #
  #         {:error, changeset} ->
  #           {:error, build_changeset(changeset)}
  #       end
  #   end
  # end

  def update(nil, _), do: {:error, :setting_not_found}

  def cast_attrs(attrs) do
    attrs
    |> cast_value()
    |> cast_options()
    |> add_position()
  end

  defp build_changeset(changeset) do
    %Changeset{
      action: changeset.action,
      changes: clean_changes(changeset.changes),
      errors: changeset.errors,
      data: %Setting{},
      valid?: changeset.valid?
    }
  end

  defp clean_changes(%{encrypted_data: data} = changes) do
    changes
    |> Map.delete(:encrypted_data)
    |> Map.put(:value, data[:value])
  end

  defp clean_changes(%{data: data} = changes) do
    changes
    |> Map.delete(:data)
    |> Map.put(:value, data[:value])
  end

  defp build(stored_setting) do
    %Setting{
      uuid: stored_setting.uuid,
      id: stored_setting.id,
      key: stored_setting.key,
      value: extract_value(stored_setting),
      type: stored_setting.type,
      description: stored_setting.description,
      options: get_options(stored_setting),
      parent: stored_setting.parent,
      parent_value: stored_setting.parent_value,
      secret: stored_setting.secret,
      position: stored_setting.position,
      inserted_at: stored_setting.inserted_at,
      updated_at: stored_setting.updated_at
    }
  end

  defp extract_value(%{secret: true, encrypted_data: nil}), do: nil

  defp extract_value(%{secret: true, encrypted_data: data}) do
    Map.get(data, :value) || Map.get(data, "value")
  end

  defp extract_value(%{secret: false, data: nil}), do: nil

  defp extract_value(%{secret: false, data: data}) do
    Map.get(data, :value) || Map.get(data, "value")
  end

  defp get_options(%{options: nil}), do: nil

  defp get_options(%{options: options}) do
    String.split(options, @split_char)
  end

  defp cast_value(%{secret: true, value: value} = attrs) do
    Map.put(attrs, :encrypted_data, %{value: value})
  end

  defp cast_value(%{value: value} = attrs) do
    Map.put(attrs, :data, %{value: value})
  end

  defp cast_value(attrs) do
    Map.put(attrs, :data, %{value: nil})
  end

  defp cast_options(%{options: options} = attrs) do
    Map.put(attrs, :options, Enum.join(options, @split_char))
  end

  defp cast_options(attrs), do: attrs

  defp add_position(%{position: position} = attrs)
       when not is_nil(position) and is_integer(position) do
    attrs
  end

  defp add_position(attrs) do
    case get_last_setting() do
      nil ->
        Map.put(attrs, :position, 0)

      latest_setting ->
        Map.put(attrs, :position, latest_setting.position + 1)
    end
  end

  defp get_last_setting do
    StoredSetting
    |> order_by(desc: :position)
    |> limit(1)
    |> Repo.one()
  end
end
