defmodule Paddle.Client do
  @moduledoc """
  Client configuration for interacting with the Paddle Billing API.

  The `%Paddle.Client{}` struct holds the API key, environment configuration,
  and the underlying HTTP client (`Req.Request`) used for making requests.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123", environment: :sandbox)

  case Paddle.Customers.create(client, email: "ada@example.com", name: "Ada Lovelace") do
    {:ok, %Paddle.Customer{} = customer} ->
      # Store customer.id
      IO.puts("Created: \#{customer.id}")

    {:error, %Paddle.Error{} = error} ->
      # Handle API or network errors
      IO.puts("Failed: \#{error.message}")
  end
  ```
  """

  @type t :: %__MODULE__{
          api_key: String.t(),
          environment: :sandbox | :live | :custom,
          base_url: String.t(),
          req: struct()
        }

  @enforce_keys [:api_key, :environment, :base_url]
  defstruct [:api_key, :environment, :base_url, :req]

  @doc """
  Creates a new client instance.

  Requires the `:api_key` option. The `:environment` defaults to `:sandbox`.
  You can override the base API URL using the `:base_url` option (useful for mock servers).

  ## Examples

  ```elixir
  client = Paddle.Client.new!(
    api_key: "sk_test_123",
    base_url: "http://localhost:4001",
    environment: :custom
  )
  ```

  ## Related Paddle docs
  - [Authentication](https://developer.paddle.com/api-reference/about/authentication)
  """
  @spec new!(keyword()) :: t()
  def new!(opts \\ []) do
    api_key = Keyword.fetch!(opts, :api_key)
    environment = Keyword.get(opts, :environment, :sandbox)

    default_url =
      if environment == :live,
        do: "https://api.paddle.com",
        else: "https://sandbox-api.paddle.com"
        
    base_url = Keyword.get(opts, :base_url, default_url)

    req =
      Req.new(
        base_url: base_url,
        auth: {:bearer, api_key},
        headers: [{"Paddle-Version", "1"}],
        retry: :transient,
        max_retries: 3
      )
      |> Paddle.Http.Telemetry.attach()

    %__MODULE__{api_key: api_key, environment: environment, base_url: base_url, req: req}
  end
end
