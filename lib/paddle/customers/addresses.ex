defmodule Paddle.Customers.Addresses do
  @moduledoc """
  Provides the interface for managing customer addresses via the Paddle Billing API.

  Addresses are associated with a customer and are used for tax calculation.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123")

  case Paddle.Customers.Addresses.get(client, "ctm_12345", "add_12345") do
    {:ok, %Paddle.Address{} = address} ->
      IO.puts("Found address in: \#{address.country_code}")

    {:error, %Paddle.Error{} = error} ->
      IO.inspect(error, label: "Paddle API Error")

    {:error, :invalid_customer_id} ->
      IO.puts("The provided customer ID was invalid.")

    {:error, :invalid_address_id} ->
      IO.puts("The provided address ID was invalid.")
  end
  ```
  """

  alias Paddle.Address
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Internal.Pagination

  @type customer_id :: String.t()
  @type address_id :: String.t()
  @type request_opt :: {:idempotency_key, String.t()} | {:retry, boolean()}

  @create_allowlist ~w(description first_line second_line city postal_code region country_code custom_data)
  @list_allowlist ~w(id after per_page order_by status search)
  @update_allowlist ~w(description first_line second_line city postal_code region country_code custom_data status)

  @doc """
  Creates a new address for a customer.

  ```elixir
  attrs = %{
    country_code: "US",
    postal_code: "10001",
    description: "Headquarters"
  }

  case Paddle.Customers.Addresses.create(client, "ctm_12345", attrs) do
    {:ok, %Paddle.Address{} = address} ->
      # Address created successfully
      address

    {:error, :invalid_customer_id} ->
      # The customer ID was empty or not a string
      :error

    {:error, :invalid_attrs} ->
      # The provided attributes were invalid
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, :invalid_attrs}`: The provided attributes were not a map or keyword list.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Provider behavior
  When creating an address, only a subset of attributes are allowed (`description`, `first_line`, `second_line`, `city`, `postal_code`, `region`, `country_code`, `custom_data`).
  If you pass extra keys, they will be silently dropped by the SDK before the request is made.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/addresses/create-address
  """
  @spec create(Paddle.Client.t(), customer_id(), map() | keyword(), [request_opt()]) ::
          {:ok, Paddle.Address.t()}
          | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_attrs}
  def create(%Paddle.Client{} = client, customer_id, attrs, opts \\ []) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             customer_addresses_path(customer_id),
             Keyword.merge([json: body], opts)
           ) do
      {:ok, Http.build_struct(Address, data)}
    end
  end

  @doc """
  Retrieves a specific address for a customer by ID.

  ## Examples

  ```elixir
  case Paddle.Customers.Addresses.get(client, "ctm_12345", "add_12345") do
    {:ok, %Paddle.Address{} = address} ->
      # Address retrieved successfully
      address

    {:error, :invalid_customer_id} ->
      # The customer ID was empty or not a string
      :error

    {:error, :invalid_address_id} ->
      # The address ID was empty or not a string
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error (e.g. 404 Not Found)
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, :invalid_address_id}`: The provided address ID was not a binary, or was an empty string.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/addresses/get-address
  """
  @spec get(Paddle.Client.t(), customer_id(), address_id()) ::
          {:ok, Paddle.Address.t()}
          | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_address_id}
  def get(%Paddle.Client{} = client, customer_id, address_id) do
    with :ok <- validate_customer_id(customer_id),
         :ok <- validate_address_id(address_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, customer_address_path(customer_id, address_id)) do
      {:ok, Http.build_struct(Address, data)}
    end
  end

  @doc """
  Lists addresses for a customer, returning a paginated `Paddle.Page`.

  ## Examples

  ```elixir
  case Paddle.Customers.Addresses.list(client, "ctm_12345", status: "active") do
    {:ok, %Paddle.Page{} = page} ->
      # Page retrieved successfully
      page.data

    {:error, :invalid_customer_id} ->
      # The customer ID was empty or not a string
      :error

    {:error, :invalid_params} ->
      # The provided query parameters were invalid
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, :invalid_params}`: The provided params were not a map or keyword list.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/addresses/list-addresses
  """
  @spec list(Paddle.Client.t(), customer_id(), map() | keyword()) ::
          {:ok, Paddle.Page.t()}
          | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_params}
  def list(%Paddle.Client{} = client, customer_id, params \\ []) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, customer_addresses_path(customer_id), params: query) do
      {:ok, build_page(data, meta)}
    end
  end

  @doc """
  Returns a `Stream` that transparently fetches all pages of addresses for a customer.

  This is useful when you want to iterate over all addresses lazily, without pulling them all into memory at once.

  ```elixir
  stream = Paddle.Customers.Addresses.stream(client, "ctm_12345", status: "active")

  # Process each address
  Enum.each(stream, fn
    {:ok, %Paddle.Address{} = address} ->
      IO.puts("Processing address: \#{address.id}")

    {:error, %Paddle.Error{} = error} ->
      IO.puts("Failed to fetch page: \#{error.message}")
  end)
  ```

  ## Errors
  - Since this returns a `Stream`, API errors are yielded as `{:error, error}` elements during enumeration.
  - Validation errors (e.g., `:invalid_customer_id`, `:invalid_params`) will be returned immediately as `{:error, atom}` by the underlying `list/3` call when iteration begins, making the first element in the stream an error tuple.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/addresses/list-addresses
  """
  @spec stream(Paddle.Client.t(), customer_id(), map() | keyword()) :: Enumerable.t()
  def stream(%Paddle.Client{} = client, customer_id, params \\ []) do
    Pagination.stream(
      fn -> list(client, customer_id, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Fetches all addresses for a customer by automatically paginating through all available pages.

  Unlike `stream/3`, this function blocks and fetches all data into a single list.

  ## Examples

  ```elixir
  case Paddle.Customers.Addresses.all(client, "ctm_12345", status: "active") do
    {:ok, addresses} when is_list(addresses) ->
      IO.puts("Fetched \#{length(addresses)} total addresses")

    {:error, :invalid_customer_id} ->
      # The customer ID was empty or not a string
      :error

    {:error, :invalid_params} ->
      # The provided query parameters were invalid
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error occurred on the first or any subsequent page
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, :invalid_params}`: The provided params were not a map or keyword list.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred during pagination.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/addresses/list-addresses
  """
  @spec all(Paddle.Client.t(), customer_id(), map() | keyword()) ::
          {:ok, [Paddle.Address.t()]}
          | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_params}
  def all(%Paddle.Client{} = client, customer_id, params \\ []) do
    Pagination.all(
      fn -> list(client, customer_id, params) end,
      fn path -> next_page(client, path) end
    )
  end

  @doc """
  Updates an existing address for a customer.

  ## Examples

  ```elixir
  attrs = %{
    description: "New Headquarters",
    status: "active"
  }

  case Paddle.Customers.Addresses.update(client, "ctm_12345", "add_12345", attrs) do
    {:ok, %Paddle.Address{} = address} ->
      # Address updated successfully
      address

    {:error, :invalid_customer_id} ->
      # The customer ID was empty or not a string
      :error

    {:error, :invalid_address_id} ->
      # The address ID was empty or not a string
      :error

    {:error, :invalid_attrs} ->
      # The provided attributes were invalid
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, :invalid_address_id}`: The provided address ID was not a binary, or was an empty string.
  - `{:error, :invalid_attrs}`: The provided attributes were not a map or keyword list.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Provider behavior
  When updating an address, only a subset of attributes are allowed (`description`, `first_line`, `second_line`, `city`, `postal_code`, `region`, `country_code`, `custom_data`, `status`).
  If you pass extra keys, they will be silently dropped by the SDK before the request is made.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/addresses/update-address
  """
  @spec update(Paddle.Client.t(), customer_id(), address_id(), map() | keyword()) ::
          {:ok, Paddle.Address.t()}
          | {:error,
             Paddle.Error.t() | :invalid_customer_id | :invalid_address_id | :invalid_attrs}
  def update(%Paddle.Client{} = client, customer_id, address_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         :ok <- validate_address_id(address_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, customer_address_path(customer_id, address_id),
             json: body
           ) do
      {:ok, Http.build_struct(Address, data)}
    end
  end

  defp customer_addresses_path(customer_id),
    do: "/customers/#{encode_path_segment(customer_id)}/addresses"

  defp next_page(client, path) do
    with {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, path) do
      {:ok, build_page(data, meta)}
    end
  end

  defp build_page(data, meta) do
    %Paddle.Page{
      data: Enum.map(data, &Http.build_struct(Address, &1)),
      meta: meta
    }
  end

  defp customer_address_path(customer_id, address_id) do
    "#{customer_addresses_path(customer_id)}/#{encode_path_segment(address_id)}"
  end

  defp validate_customer_id(customer_id), do: validate_id(customer_id, :invalid_customer_id)
  defp validate_address_id(address_id), do: validate_id(address_id, :invalid_address_id)

  defp validate_id(id, error) when is_binary(id) do
    if String.trim(id) == "" do
      {:error, error}
    else
      :ok
    end
  end

  defp validate_id(_id, error), do: {:error, error}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
