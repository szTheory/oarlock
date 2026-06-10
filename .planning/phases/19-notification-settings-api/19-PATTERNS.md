# Phase 19: Notification Settings API - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/paddle/notification_setting.ex` | model | struct | `lib/paddle/customer.ex` | exact |
| `lib/paddle/notification_settings.ex` | service | CRUD | `lib/paddle/customers.ex` (mutations), `lib/paddle/products.ex` (reads) | exact |
| `test/paddle/notification_setting_test.exs` | test | struct | `test/paddle/customer_test.exs` | exact |
| `test/paddle/notification_settings_test.exs` | test | CRUD | `test/paddle/customers_test.exs` | exact |

## Pattern Assignments

### `lib/paddle/notification_setting.ex` (model, struct)

**Analog:** `lib/paddle/customer.ex`

**Struct definition pattern** (lines 16-39):
```elixir
  @type t :: %__MODULE__{
          # ... types ...
          raw_data: map() | nil
        }

  defstruct [
    # ... fields ...
    :raw_data
  ]
```

---

### `lib/paddle/notification_settings.ex` (service, CRUD)

**Analogs:** `lib/paddle/products.ex` (reads), `lib/paddle/customers.ex` (mutations), `19-RESEARCH.md` (deletes)

**Imports pattern** (`lib/paddle/products.ex` lines 22-26):
```elixir
  alias Paddle.Client
  alias Paddle.NotificationSetting
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination
```

**Allowlist pattern** (`lib/paddle/customers.ex` lines 27-28):
```elixir
  @create_allowlist ~w(description destination type subscribed_events api_version include_sensitive_fields active)
  @update_allowlist ~w(description destination active subscribed_events include_sensitive_fields)
  @list_allowlist ~w(after id order_by per_page)
```

**Create pattern** (`lib/paddle/customers.ex` lines 73-82):
```elixir
  @spec create(Paddle.Client.t(), map() | keyword(), [request_opt()]) ::
          {:ok, Paddle.NotificationSetting.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
  def create(%Client{} = client, attrs, opts \\ []) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, "/notification-settings", Keyword.merge([json: body], opts)) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end
```

**Get pattern** (`lib/paddle/products.ex` lines 38-46):
```elixir
  @spec get(Paddle.Client.t(), notification_setting_id()) ::
          {:ok, Paddle.NotificationSetting.t()} | {:error, Paddle.Error.t() | :invalid_notification_setting_id}
  def get(%Client{} = client, notification_setting_id) do
    with :ok <- validate_id(notification_setting_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, notification_setting_path(notification_setting_id)) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end
```

**List/Stream/All pattern** (`lib/paddle/products.ex` lines 54-85):
```elixir
  @spec list(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.Page.t()} | {:error, Paddle.Error.t() | :invalid_params}
  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/notification-settings", params: query) do
      {:ok, build_page(data, meta)}
    end
  end

  @spec stream(Paddle.Client.t(), map() | keyword()) :: Enumerable.t()
  def stream(%Client{} = client, params \\ []) do
    Pagination.stream(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @spec all(Paddle.Client.t(), map() | keyword()) ::
          {:ok, [Paddle.NotificationSetting.t()]} | {:error, Paddle.Error.t() | :invalid_params}
  def all(%Client{} = client, params \\ []) do
    Pagination.all(
      fn -> list(client, params) end,
      fn path -> next_page(client, path) end
    )
  end
```

**Update pattern** (`lib/paddle/customers.ex` lines 164-175):
```elixir
  @spec update(Paddle.Client.t(), notification_setting_id(), map() | keyword()) ::
          {:ok, Paddle.NotificationSetting.t()}
          | {:error, Paddle.Error.t() | :invalid_notification_setting_id | :invalid_attrs}
  def update(%Client{} = client, notification_setting_id, attrs) do
    with :ok <- validate_id(notification_setting_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, notification_setting_path(notification_setting_id), json: body) do
      {:ok, Http.build_struct(NotificationSetting, data)}
    end
  end
```

**Delete pattern** (`19-RESEARCH.md` explicit excerpt):
```elixir
  @spec delete(Paddle.Client.t(), notification_setting_id()) ::
          :ok | {:error, Paddle.Error.t() | :invalid_notification_setting_id}
  def delete(%Client{} = client, id) do
    with :ok <- validate_id(id),
         {:ok, _} <- Http.request(client, :delete, notification_setting_path(id)) do
      :ok
    end
  end
```

**Path and validation helpers** (`lib/paddle/products.ex` lines 87-109):
```elixir
  defp validate_id(id) when is_binary(id) do
    if String.trim(id) == "" do
      {:error, :invalid_notification_setting_id}
    else
      :ok
    end
  end

  defp validate_id(_id), do: {:error, :invalid_notification_setting_id}

  defp notification_setting_path(id), do: "/notification-settings/\#{encode_path_segment(id)}"
  
  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
```

---

### `test/paddle/notification_setting_test.exs` (test, struct)

**Analog:** `test/paddle/customer_test.exs`

**Struct definition test pattern** (lines 8-22):
```elixir
  describe "struct" do
    test "exposes the promoted fields plus raw_data" do
      assert %NotificationSetting{
               id: nil,
               # ...
               raw_data: nil
             } = %NotificationSetting{}
    end
```

**Struct build test pattern** (lines 24-51):
```elixir
    test "build_struct/2 promotes known keys and preserves the full payload in raw_data" do
      data = %{
        "id" => "not_01",
        # ...
        "ignored_key" => "kept in raw only"
      }

      assert %NotificationSetting{
               id: "not_01",
               # ...
               raw_data: ^data
             } = Http.build_struct(NotificationSetting, data)
    end
  end
```

---

### `test/paddle/notification_settings_test.exs` (test, CRUD)

**Analog:** `test/paddle/customers_test.exs`

**Client Mocking Pattern** (lines 13-26):
```elixir
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/notification-settings"

          assert decode_json_body(request.body) == %{
                   # expected json map ...
                 }

          {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
        end)
```

**Error Handling Test Pattern** (lines 53-73):
```elixir
    test "preserves non-2xx API error tuples from Paddle.Http.request/4" do
      client =
        client_with_adapter(fn request ->
          response =
            Req.Response.new(
              status: 422,
              body: %{
                "error" => %{
                  # error shape ...
                }
              }
            )
          {request, response}
        end)

      assert {:error, %Error{status_code: 422}} = NotificationSettings.create(client, %{type: "invalid"})
    end
```

## Shared Patterns

### HTTP Struct Building
**Source:** `Paddle.Http`
**Apply to:** All response parsers
```elixir
{:ok, Http.build_struct(NotificationSetting, data)}
```

### Params Normalization
**Source:** `Paddle.Internal.Attrs`
**Apply to:** List and Create/Update functions
```elixir
{:ok, attrs} <- Attrs.normalize(attrs),
body <- Attrs.allowlist(attrs, @create_allowlist)
```

### Cursor-Based Pagination
**Source:** `Paddle.Internal.Pagination`
**Apply to:** List/Stream/All functions
```elixir
{:ok, build_page(data, meta)}
# Handled via Pagination.build_page
```

## Metadata

**Analog search scope:** `lib/paddle/**/*.ex`, `test/paddle/**/*.exs`
**Files scanned:** 8
**Pattern extraction date:** 2026-06-10
