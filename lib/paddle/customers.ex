defmodule Paddle.Customers do
  @moduledoc """
  Provides the interface for managing customers via the Paddle Billing API.

  Customers are the entities that purchase your products.

  Customer reads use bounded retries for documented transient failures.
  Creates and updates always make one attempt; `retry: true` and
  `idempotency_key` are unsupported. Ambiguous mutation failures return a
  non-retryable `%Paddle.Error{}` with a static operation and, for updates,
  the customer resource ID plus fixed consumer reconciliation actions.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123")

  case Paddle.Customers.get(client, "ctm_12345") do
    {:ok, %Paddle.Customer{} = customer} ->
      IO.puts("Found customer: \#{customer.email}")

    {:error, %Paddle.Error{} = error} ->
      IO.inspect(error, label: "Paddle API Error")

    {:error, :invalid_customer_id} ->
      IO.puts("The provided customer ID was invalid.")
  end
  ```
  """

  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Http
  alias Paddle.Internal.Attrs

  @type customer_id :: String.t()
  @type request_opt :: {:retry, boolean()}

  @create_allowlist ~w(email name custom_data locale)
  @update_allowlist ~w(name email status custom_data locale)

  @doc """
  Creates a new customer.

  This mutation makes one attempt. `retry: true` and `idempotency_key` are
  rejected before dispatch. Ambiguous failures expose only the static
  `:create_customer` operation and fixed reconciliation actions.

  ## Examples

  ```elixir
  attrs = %{
    email: "jane.doe@example.com",
    name: "Jane Doe"
  }

  case Paddle.Customers.create(client, attrs) do
    {:ok, %Paddle.Customer{} = customer} ->
      # Customer created successfully
      customer

    {:error, :invalid_attrs} ->
      # The provided attributes were invalid
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_attrs}`: The provided attributes were not a map or keyword list.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Provider behavior
  When creating a customer, only a subset of attributes are allowed (`email`, `name`, `custom_data`, `locale`).
  If you pass extra keys, they will be silently dropped by the SDK before the request is made.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/customers/create-customer
  """
  @spec create(Paddle.Client.t(), map() | keyword(), [request_opt()]) ::
          {:ok, Paddle.Customer.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
  def create(%Client{} = client, attrs, opts \\ []) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             "/customers",
             Keyword.merge([json: body, operation: :create_customer, route: "/customers"], opts)
           ) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  @doc """
  Retrieves a specific customer by ID.

  This safe read uses bounded transient retries. The runtime customer ID is
  encoded only into the dispatch path; telemetry uses the literal normalized
  route `/customers/:customer_id`.

  ## Examples

  ```elixir
  case Paddle.Customers.get(client, "ctm_12345") do
    {:ok, %Paddle.Customer{} = customer} ->
      # Customer retrieved successfully
      customer

    {:error, :invalid_customer_id} ->
      # The customer ID was empty or not a string
      :error

    {:error, %Paddle.Error{} = error} ->
      # Paddle API error (e.g. 404 Not Found)
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/customers/get-customer
  """
  @spec get(Paddle.Client.t(), customer_id()) ::
          {:ok, Paddle.Customer.t()} | {:error, Paddle.Error.t() | :invalid_customer_id}
  def get(%Client{} = client, customer_id) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, customer_path(customer_id),
             operation: :get_customer,
             route: "/customers/:customer_id"
           ) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  @doc """
  Updates an existing customer.

  This mutation makes one attempt. Ambiguous transport or terminal HTTP
  408/5xx failures return a non-retryable `%Paddle.Error{}` with
  `operation: :update_customer`, the validated customer resource ID, and the
  fixed consumer reconciliation actions. Automatic replay and idempotency
  keys are unsupported.

  ## Examples

  ```elixir
  attrs = %{
    name: "Jane Smith",
    status: "active"
  }

  case Paddle.Customers.update(client, "ctm_12345", attrs) do
    {:ok, %Paddle.Customer{} = customer} ->
      # Customer updated successfully
      customer

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
  When updating a customer, only a subset of attributes are allowed (`name`, `email`, `status`, `custom_data`, `locale`).
  If you pass extra keys, they will be silently dropped by the SDK before the request is made.

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/customers/update-customer
  """
  @spec update(Paddle.Client.t(), customer_id(), map() | keyword()) ::
          {:ok, Paddle.Customer.t()}
          | {:error, Paddle.Error.t() | :invalid_customer_id | :invalid_attrs}
  def update(%Client{} = client, customer_id, attrs) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @update_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :patch, customer_path(customer_id),
             json: body,
             operation: :update_customer,
             route: "/customers/:customer_id",
             resource_id: customer_id
           ) do
      {:ok, Http.build_struct(Customer, data)}
    end
  end

  defp customer_path(customer_id), do: "/customers/#{encode_path_segment(customer_id)}"

  defp validate_customer_id(customer_id) when is_binary(customer_id) do
    if String.trim(customer_id) == "" do
      {:error, :invalid_customer_id}
    else
      :ok
    end
  end

  defp validate_customer_id(_customer_id), do: {:error, :invalid_customer_id}

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
