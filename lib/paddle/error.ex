defmodule Paddle.Error do
  @moduledoc """
  Represents normalized network and provider-side errors.

  Rather than returning disparate raw HTTP errors, Req exceptions, or nested Paddle error bodies,
  the SDK normalizes all API and transport errors into a single `%Paddle.Error{}` struct.
  This struct preserves the original Paddle `code` and `request_id` for debugging. A
  body `meta.request_id` takes precedence over the `x-request-id` response header.

  Mutation transport failures and terminal HTTP 408/5xx responses are explicitly
  ambiguous and non-retryable because Paddle may have applied the operation. They
  retain only the static operation, an optional safe resource ID, provider request
  ID when available, and consumer-owned reconciliation actions (`:lookup`,
  `:webhook`, and `:provider_dashboard`). The SDK never replays or reconciles a
  mutation automatically.

  Inspecting an error redacts provider-controlled `message` and `errors` fields plus
  `raw_data` wholesale. Those values remain available to the caller, but arbitrary
  provider payloads and exception contents are never rendered by `inspect/1`.

  If a request fails before reaching Paddle (e.g., local validation), the SDK returns
  an atom like `{:error, :invalid_id}`. Once a request hits the network, failures are
  returned as `{:error, %Paddle.Error{}}`.

  ## Examples

  ```elixir
  case Paddle.Customers.get(client, "ctm_123") do
    {:ok, %Paddle.Customer{} = customer} ->
      customer

    {:error, %Paddle.Error{code: "not_found", status_code: 404}} ->
      # Resource not found on Paddle

    {:error, %Paddle.Error{network_error?: true}} ->
      # A transport issue (e.g., timeout)
  end
  ```

  ## Related Paddle docs
  - [Errors](https://developer.paddle.com/api-reference/about/errors)
  """

  @type reconciliation_action :: :lookup | :webhook | :provider_dashboard
  @type context :: %{
          optional(:method) => atom(),
          optional(:operation) => atom(),
          optional(:resource_id) => String.t()
        }

  @type t :: %__MODULE__{
          type: String.t() | nil,
          code: String.t() | nil,
          message: String.t() | nil,
          errors: list(map()),
          request_id: String.t() | nil,
          status_code: integer() | nil,
          raw_data: map() | struct() | nil,
          network_error?: boolean(),
          retryable?: boolean(),
          ambiguous?: boolean(),
          operation: atom() | nil,
          resource_id: String.t() | nil,
          reconciliation: [reconciliation_action()]
        }

  defexception type: nil,
               code: nil,
               message: nil,
               errors: [],
               request_id: nil,
               status_code: nil,
               raw_data: nil,
               network_error?: false,
               retryable?: false,
               ambiguous?: false,
               operation: nil,
               resource_id: nil,
               reconciliation: []

  @mutation_methods [:post, :patch, :put, :delete]
  @reconciliation_actions [:lookup, :webhook, :provider_dashboard]

  @impl Exception
  @spec message(t()) :: String.t()
  def message(%{message: message}), do: message || ""

  @doc """
  Normalizes a provider response without request context.

  This compatibility entry point delegates to `from_response/2` with empty
  context. Use `from_response/2` at the request boundary so mutation ambiguity,
  static operation/resource context, and request-ID precedence are retained.
  """
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{} = response), do: from_response(response, %{})

  @doc """
  Normalizes a provider response with safe request context.

  A body `meta.request_id` wins over `x-request-id`. Mutation HTTP 408 and 5xx
  responses are marked ambiguous, non-retryable, and expose only documented
  consumer-owned reconciliation actions.
  """
  @spec from_response(Req.Response.t(), context()) :: t()
  def from_response(%Req.Response{status: status, body: body} = resp, context) do
    body = if is_map(body), do: body, else: %{}
    error_body = normalize_error_body(Map.get(body, "error"))
    ambiguous? = ambiguous_response?(status, context)

    %__MODULE__{
      status_code: status,
      request_id: provider_request_id(body, resp),
      type: binary_or_nil(Map.get(error_body, "type")),
      code: binary_or_nil(Map.get(error_body, "code")),
      message: error_message(Map.get(error_body, "detail")),
      errors: normalize_errors(Map.get(error_body, "errors")),
      raw_data: body,
      ambiguous?: ambiguous?,
      operation: context[:operation],
      resource_id: context[:resource_id],
      reconciliation: reconciliation(ambiguous?)
    }
  end

  @doc """
  Normalizes a transport exception without request context.

  This compatibility entry point delegates to `from_transport/2`. Without a
  mutation method the result retains the existing retryable network-error
  classification and is not marked ambiguous.
  """
  @spec from_transport(Exception.t()) :: t()
  def from_transport(%Req.TransportError{} = exception), do: from_transport(exception, %{})

  @doc """
  Normalizes a transport exception with safe request context.

  Mutation transport failures are ambiguous and non-retryable. The returned
  error carries only static operation/resource identity and the reconciliation
  atoms `:lookup`, `:webhook`, and `:provider_dashboard`; it never replays the
  mutation or includes request bodies in guidance.
  """
  @spec from_transport(Exception.t(), context()) :: t()
  def from_transport(%Req.TransportError{reason: reason} = exception, context) do
    ambiguous? = mutation?(context)

    %__MODULE__{
      type: transport_type(reason),
      message: Exception.message(exception),
      network_error?: true,
      retryable?: not ambiguous?,
      raw_data: exception,
      ambiguous?: ambiguous?,
      operation: context[:operation],
      resource_id: context[:resource_id],
      reconciliation: reconciliation(ambiguous?)
    }
  end

  defp ambiguous_response?(408, context), do: mutation?(context)
  defp ambiguous_response?(status, context) when status in 500..599, do: mutation?(context)
  defp ambiguous_response?(_status, _context), do: false

  defp mutation?(context), do: context[:method] in @mutation_methods

  defp reconciliation(true), do: @reconciliation_actions
  defp reconciliation(false), do: []

  defp normalize_error_body(error_body) when is_map(error_body), do: error_body
  defp normalize_error_body(_error_body), do: %{}

  defp binary_or_nil(value) when is_binary(value), do: value
  defp binary_or_nil(_value), do: nil

  defp error_message(value) when is_binary(value), do: value
  defp error_message(_value), do: "Unknown Paddle Error"

  defp normalize_errors(errors) when is_list(errors), do: Enum.filter(errors, &is_map/1)
  defp normalize_errors(_errors), do: []

  defp provider_request_id(body, response) do
    case body_request_id(body) do
      request_id when is_binary(request_id) and request_id != "" -> request_id
      _other -> response |> Req.Response.get_header("x-request-id") |> List.first()
    end
  end

  defp body_request_id(%{"meta" => %{} = meta}), do: Map.get(meta, "request_id")
  defp body_request_id(_body), do: nil

  defp transport_type(:timeout), do: "network_timeout"
  defp transport_type(:nxdomain), do: "network_nxdomain"
  defp transport_type(:closed), do: "network_closed"
  defp transport_type(_), do: "network_unknown"
end

defimpl Inspect, for: Paddle.Error do
  import Inspect.Algebra

  def inspect(error, opts) do
    fields =
      error
      |> Map.from_struct()
      |> Map.replace!(:message, "[REDACTED]")
      |> Map.replace!(:errors, "[REDACTED]")
      |> Map.replace!(:raw_data, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.Error{", to_doc(fields, opts), "}"])
  end
end
