defmodule Paddle.Error do
  @moduledoc """
  Represents normalized network and provider-side errors.

  Rather than returning disparate raw HTTP errors, Req exceptions, or nested Paddle error bodies,
  the SDK normalizes all API and transport errors into a single `%Paddle.Error{}` struct.
  This struct preserves the original Paddle `code` and `request_id` for debugging.

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

  @type t :: %__MODULE__{
          type: String.t() | nil,
          code: String.t() | nil,
          message: String.t() | nil,
          errors: list(map()),
          request_id: String.t() | nil,
          status_code: integer() | nil,
          raw_data: map() | struct() | nil,
          network_error?: boolean(),
          retryable?: boolean()
        }

  defexception type: nil,
               code: nil,
               message: nil,
               errors: [],
               request_id: nil,
               status_code: nil,
               raw_data: nil,
               network_error?: false,
               retryable?: false

  @impl Exception
  @spec message(t()) :: String.t()
  def message(%{message: message}), do: message || ""

  @doc false
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{status: status, body: body} = resp) do
    body = if is_map(body), do: body, else: %{}
    error_body = Map.get(body, "error", %{})

    %__MODULE__{
      status_code: status,
      request_id: resp |> Req.Response.get_header("x-request-id") |> List.first(),
      type: error_body["type"],
      code: error_body["code"],
      message: Map.get(error_body, "detail", "Unknown Paddle Error"),
      errors: Map.get(error_body, "errors", []),
      raw_data: body
    }
  end

  @doc false
  @spec from_transport(Exception.t()) :: t()
  def from_transport(%Req.TransportError{reason: reason} = exception) do
    %__MODULE__{
      type: transport_type(reason),
      message: Exception.message(exception),
      network_error?: true,
      retryable?: true,
      raw_data: exception
    }
  end

  defp transport_type(:timeout), do: "network_timeout"
  defp transport_type(:nxdomain), do: "network_nxdomain"
  defp transport_type(:closed), do: "network_closed"
  defp transport_type(_), do: "network_unknown"
end