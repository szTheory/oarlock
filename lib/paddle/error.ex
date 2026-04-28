defmodule Paddle.Error do
  defexception [:type, :code, :message, :errors, :request_id, :status_code, :raw]

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
      raw: body
    }
  end
end
