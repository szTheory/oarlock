defmodule Paddle.NotificationSettings do
  @moduledoc """
  Provides the interface for managing notification settings via the Paddle Billing API.

  Reads use bounded retries for documented transient failures, including every
  pagination continuation. Creates, updates, and deletes always make one
  attempt; `retry: true` and `idempotency_key` are unsupported. Ambiguous
  mutation failures expose only a static operation, an optional validated
  notification-setting ID, and fixed consumer reconciliation actions. Runtime
  IDs, filters, cursors, destinations, and endpoint secrets are never route
  metadata.
  """

  alias Paddle.Client
  alias Paddle.NotificationSetting
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination

  @type notification_setting_id :: String.t()
  @type request_opt :: {:retry, boolean()}

  @list_allowlist ~w(after id order_by per_page)
  @create_allowlist ~w(description destination type subscribed_events api_version include_sensitive_fields active)
  @update_allowlist ~w(description destination active subscribed_events include_sensitive_fields)

  @doc """
  Creates a new notification setting.

  This mutation makes one attempt. `retry: true` and `idempotency_key` are
  rejected before dispatch. Ambiguous failures expose only the static
  `:create_notification_setting` operation and fixed reconciliation actions;
  destinations and endpoint secrets never enter request context.
  """
  @spec create(Paddle.Client.t(), map() | keyword(), [request_opt()]) ::
          {:ok, Paddle.NotificationSetting.t()}
          | {:error, Paddle.Error.t() | :invalid_attrs | :missing_api_version}
  def create(%Client{} = client, attrs, opts \\ []) do
    opts = Http.validate_public_request_opts!(opts)

    with {:ok, attrs} <- Attrs.normalize(attrs),
         :ok <- validate_api_version(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             "/notification-settings",
             Keyword.merge(opts,
               json: body,
               operation: :create_notification_setting,
               route: "/notification-settings"
             )
           ) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end

  @doc """
  Retrieves a notification setting by ID.

  This bounded read is labeled with the static `:get_notification_setting`
  operation and `/notification-settings/:notification_setting_id` route. The
  runtime ID is used only in the encoded dispatch path.
  """
  @spec get(Paddle.Client.t(), notification_setting_id()) ::
          {:ok, Paddle.NotificationSetting.t()}
          | {:error, Paddle.Error.t() | :invalid_notification_setting_id}
  def get(%Client{} = client, id) do
    with :ok <- validate_id(id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, path(id),
             operation: :get_notification_setting,
             route: "/notification-settings/:notification_setting_id"
           ) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end

  @doc """
  Lists notification settings.

  The first page and every continuation are bounded reads labeled with the
  static `:list_notification_settings` operation and `/notification-settings`
  route. Filters and cursors remain dispatch-only.
  """
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/notification-settings",
             params: query,
             operation: :list_notification_settings,
             route: "/notification-settings"
           ) do
      {:ok, Pagination.build_page(NotificationSetting, data, meta)}
    end
  end

  @doc """
  Returns a stream of notification settings using bounded, statically labeled reads.
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

  Every page uses the bounded, statically labeled list-read contract.
  """
  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.NotificationSetting.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn next_path -> next_page(client, next_path) end
    )
  end

  @doc """
  Updates an existing notification setting.

  This mutation makes one attempt. Ambiguous failures expose the static
  `:update_notification_setting` operation, the validated setting ID, and fixed
  reconciliation actions. Automatic replay and idempotency keys are unsupported.
  """
  @spec update(Paddle.Client.t(), notification_setting_id(), map() | keyword()) ::
          {:ok, Paddle.NotificationSetting.t()}
          | {:error, Paddle.Error.t() | :invalid_notification_setting_id | :invalid_attrs}
  def update(%Client{} = client, id, attrs) do
    with :ok <- validate_id(id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, path(id),
             json: body,
             operation: :update_notification_setting,
             route: "/notification-settings/:notification_setting_id",
             resource_id: id
           ) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end

  @doc """
  Deletes an existing notification setting.

  This mutation makes one attempt. Ambiguous failures expose the static
  `:delete_notification_setting` operation, the validated setting ID, and fixed
  reconciliation actions. Automatic replay and idempotency keys are unsupported.
  """
  @spec delete(Paddle.Client.t(), notification_setting_id()) ::
          :ok | {:error, Paddle.Error.t() | :invalid_notification_setting_id}
  def delete(%Client{} = client, id) do
    with :ok <- validate_id(id),
         {:ok, _} <-
           Http.request(client, :delete, path(id),
             operation: :delete_notification_setting,
             route: "/notification-settings/:notification_setting_id",
             resource_id: id
           ) do
      :ok
    end
  end

  defp validate_api_version(attrs) do
    if Map.has_key?(attrs, "api_version") do
      :ok
    else
      {:error, :missing_api_version}
    end
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
    Pagination.next_page(client, NotificationSetting, path,
      operation: :list_notification_settings,
      route: "/notification-settings"
    )
  end
end
