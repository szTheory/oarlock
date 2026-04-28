defmodule Paddle.Http.Telemetry do
  def attach(req) do
    req
    |> Req.Request.append_request_steps(paddle_telemetry_start: &telemetry_start/1)
    |> Req.Request.append_response_steps(paddle_telemetry_stop: &telemetry_stop/1)
    |> Req.Request.append_error_steps(paddle_telemetry_error: &telemetry_error/1)
  end

  defp telemetry_start(request) do
    :telemetry.execute([:paddle, :request, :start], %{time: System.system_time()}, %{request: request})
    request
  end

  defp telemetry_stop({request, response}) do
    :telemetry.execute(
      [:paddle, :request, :stop],
      %{time: System.system_time()},
      %{request: request, response: response}
    )

    {request, response}
  end

  defp telemetry_error({request, exception}) do
    :telemetry.execute(
      [:paddle, :request, :exception],
      %{time: System.system_time()},
      %{request: request, exception: exception}
    )

    {request, exception}
  end
end
