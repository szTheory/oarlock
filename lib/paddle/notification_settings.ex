defmodule Paddle.NotificationSettings do
  @moduledoc """
  Provides the interface for managing notification settings via the Paddle Billing API.
  """

  alias Paddle.Client
  alias Paddle.NotificationSetting
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination

  @type notification_setting_id :: String.t()

  @list_allowlist ~w(after id order_by per_page)

  @doc """
  Retrieves a notification setting by ID.
  """
  @spec get(Paddle.Client.t(), notification_setting_id()) ::
          {:ok, Paddle.NotificationSetting.t()}
          | {:error, Paddle.Error.t() | :invalid_notification_setting_id}
  def get(%Client{} = client, id) do
    with :ok <- validate_id(id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, path(id)) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end

  @doc """
  Lists notification settings.
  """
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/notification-settings", params: query) do
      {:ok, Pagination.build_page(NotificationSetting, data, meta)}
    end
  end

  @doc """
  Returns a stream of notification settings.
  """
  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn next_path -> next_page(client, next_path) end
    )
  end

  @doc """
  Retrieves all notification settings, automatically handling pagination.
  """
  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.NotificationSetting.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn next_path -> next_page(client, next_path) end
    )
  end

  defp validate_id(id) when is_binary(id) do
    if String.trim(id) == "" do
      {:error, :invalid_notification_setting_id}
    else
      :ok
    end
  end

  defp validate_id(_id), do: {:error, :invalid_notification_setting_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp path(id), do: "/notification-settings/#{encode_path_segment(id)}"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)

  defp next_page(client, path) do
    with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, path) do
      {:ok, Pagination.build_page(NotificationSetting, data, meta)}
    end
  end
end
