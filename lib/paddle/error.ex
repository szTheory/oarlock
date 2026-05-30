defmodule Paddle.Error do
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
  def message(%{message: message}), do: message

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
