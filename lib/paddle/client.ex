defmodule Paddle.Client do
  alias Paddle.Http.Telemetry

  @moduledoc """
  Client configuration for interacting with the Paddle Billing API.

  The `%Paddle.Client{}` struct holds a validated, nonblank API key, an explicit
  environment identity, an absolute HTTP(S) base URL, and the underlying HTTP
  client (`Req.Request`) used for making requests.

  Construction accepts only the unique options `:api_key`, `:environment`, and
  `:base_url`. The supported environments are `:sandbox`, `:live`, and
  `:custom`. Sandbox and live clients use their canonical Paddle URLs. A valid
  noncanonical `:base_url` without an explicit environment is classified as
  `:custom`, while `environment: :custom` requires a base URL.

  Invalid configuration raises `ArgumentError` before Req is built or a request
  is dispatched. Error messages identify only the invalid option and never its
  value. Inspecting a client leaves `environment` visible but replaces
  `api_key`, `base_url`, and `req` wholesale with the stable `[REDACTED]`
  marker; this representation does not change the stored runtime fields.

  Retry eligibility is owned by `Paddle.Http` for each request. Only `GET` and
  `HEAD` may retry documented transient failures; mutations cannot opt into
  replay, and `retry: false` can further restrict a read. The unsupported
  `idempotency_key` option is never converted into a request header.

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

  @type environment :: :sandbox | :live | :custom
  @type option ::
          {:api_key, String.t()}
          | {:environment, environment()}
          | {:base_url, String.t()}

  @type t :: %__MODULE__{
          api_key: String.t(),
          environment: environment(),
          base_url: String.t(),
          req: struct()
        }

  @enforce_keys [:api_key, :environment, :base_url]
  defstruct [:api_key, :environment, :base_url, :req]

  @doc """
  Creates a new client instance.

  Requires a nonblank binary `:api_key`. The `:environment` defaults to
  `:sandbox`. The only accepted options are `:api_key`, `:environment`, and
  `:base_url`, and each may appear only once.

  The `:base_url` must be an absolute HTTP(S) URL with a host. Supplying only a
  noncanonical base URL infers `:custom`, which supports deliberate MockServer
  use. Explicit `:sandbox` and `:live` environments accept only their matching
  canonical URLs; explicit `:custom` requires a base URL.

  Invalid options raise `ArgumentError` before Req construction or dispatch.
  Exceptions name the invalid option without rendering its value.

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
  @spec new!([option()]) :: t()
  def new!(opts \\ []) do
    opts = validate_options!(opts)
    api_key = validate_api_key!(opts)
    {environment, base_url} = resolve_environment_and_base_url!(opts)

    req =
      Req.new(
        base_url: base_url,
        auth: {:bearer, api_key},
        headers: [{"Paddle-Version", "1"}],
        retry: false
      )
      |> Telemetry.attach()

    %__MODULE__{api_key: api_key, environment: environment, base_url: base_url, req: req}
  end

  @known_options [:api_key, :environment, :base_url]
  @sandbox_url "https://sandbox-api.paddle.com"
  @live_url "https://api.paddle.com"

  defp validate_options!(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      option_names = Keyword.keys(opts)

      case Enum.find(option_names, &(&1 not in @known_options)) do
        nil -> :ok
        option -> raise ArgumentError, "unknown client option #{inspect(option)}"
      end

      validate_unique_options!(option_names, opts)
    else
      raise ArgumentError, "client options must be a keyword list"
    end
  end

  defp validate_options!(_opts), do: raise(ArgumentError, "client options must be a keyword list")

  defp validate_unique_options!(option_names, opts) do
    case Enum.find(Enum.frequencies(option_names), fn {_option, count} -> count > 1 end) do
      nil -> opts
      {option, _count} -> raise ArgumentError, "duplicate client option #{inspect(option)}"
    end
  end

  defp validate_api_key!(opts) do
    case Keyword.fetch(opts, :api_key) do
      {:ok, api_key} when is_binary(api_key) ->
        if String.trim(api_key) == "" do
          raise ArgumentError, "client option :api_key must be a nonblank binary"
        else
          api_key
        end

      _other ->
        raise ArgumentError, "client option :api_key must be a nonblank binary"
    end
  end

  defp resolve_environment_and_base_url!(opts) do
    case {Keyword.fetch(opts, :environment), Keyword.fetch(opts, :base_url)} do
      {:error, :error} -> {:sandbox, @sandbox_url}
      {:error, {:ok, base_url}} -> resolve_base_url_only!(base_url)
      {{:ok, environment}, base_url} -> resolve_explicit_environment!(environment, base_url)
    end
  end

  defp resolve_base_url_only!(base_url) do
    base_url = validate_base_url!(base_url)
    {environment_for_url(base_url), base_url}
  end

  defp resolve_explicit_environment!(:sandbox, :error), do: {:sandbox, @sandbox_url}
  defp resolve_explicit_environment!(:live, :error), do: {:live, @live_url}

  defp resolve_explicit_environment!(:custom, :error),
    do: raise(ArgumentError, "client option :base_url is required for environment :custom")

  defp resolve_explicit_environment!(:sandbox, {:ok, base_url}) do
    validate_canonical_base_url!(base_url, @sandbox_url)
    {:sandbox, @sandbox_url}
  end

  defp resolve_explicit_environment!(:live, {:ok, base_url}) do
    validate_canonical_base_url!(base_url, @live_url)
    {:live, @live_url}
  end

  defp resolve_explicit_environment!(:custom, {:ok, base_url}),
    do: {:custom, validate_base_url!(base_url)}

  defp resolve_explicit_environment!(_environment, _base_url),
    do: raise(ArgumentError, "client option :environment is unsupported")

  defp environment_for_url(@sandbox_url), do: :sandbox
  defp environment_for_url(@live_url), do: :live
  defp environment_for_url(_base_url), do: :custom

  defp validate_canonical_base_url!(base_url, canonical_url) do
    if validate_base_url!(base_url) != canonical_url do
      raise ArgumentError, "client option :base_url conflicts with :environment"
    end
  end

  defp validate_base_url!(base_url) when is_binary(base_url) do
    case URI.new(base_url) do
      {:ok, %URI{scheme: scheme, host: host}}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        if String.trim(host) == "" do
          raise ArgumentError,
                "client option :base_url must be an absolute HTTP(S) URL with a host"
        else
          base_url
        end

      _other ->
        raise ArgumentError, "client option :base_url must be an absolute HTTP(S) URL with a host"
    end
  end

  defp validate_base_url!(_base_url) do
    raise ArgumentError, "client option :base_url must be an absolute HTTP(S) URL with a host"
  end
end

defimpl Inspect, for: Paddle.Client do
  import Inspect.Algebra

  def inspect(client, opts) do
    fields =
      client
      |> Map.from_struct()
      |> Map.replace!(:api_key, "[REDACTED]")
      |> Map.replace!(:base_url, "[REDACTED]")
      |> Map.replace!(:req, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.Client{", to_doc(fields, opts), "}"])
  end
end
