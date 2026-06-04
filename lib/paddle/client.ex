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
      IO.puts("Created: #{customer.id}")

    {:error, %Paddle.Error{} = error} ->
      # Handle API or network errors
      IO.puts("Failed: #{error.message}")
  end
  ```
  """

  @type t :: %__MODULE__{
          api_key: String.t(),
          environment: :sandbox | :live,
          req: struct()
        }

  @enforce_keys [:api_key, :environment]
  defstruct [:api_key, :environment, :req]

  @doc """
  Creates a new client instance.

  Requires the `:api_key` option. The `:environment` defaults to `:sandbox`.

  ## Examples

  ```elixir
  client = Paddle.Client.new!(
    api_key: "sk_test_123",
    environment: :sandbox
  )
  ```

  ## Related Paddle docs
  - [Authentication](https://developer.paddle.com/api-reference/about/authentication)
  """
  @spec new!(keyword()) :: t()
  def new!(opts \\ []) do
    api_key = Keyword.fetch!(opts, :api_key)
    environment = Keyword.get(opts, :environment, :sandbox)

    base_url =
      if environment == :live,
        do: "https://api.paddle.com",
        else: "https://sandbox-api.paddle.com"

    req =
      Req.new(
        base_url: base_url,
        auth: {:bearer, api_key},
        headers: [{"Paddle-Version", "1"}],
        retry: :transient,
        max_retries: 3
      )
      |> Paddle.Http.Telemetry.attach()

    %__MODULE__{api_key: api_key, environment: environment, req: req}
  end
end
