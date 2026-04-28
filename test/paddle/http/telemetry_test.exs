defmodule Paddle.Http.TelemetryTest do
  use ExUnit.Case, async: true

  setup do
    handler_id = {__MODULE__, make_ref()}

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:paddle, :request, :start],
          [:paddle, :request, :stop],
          [:paddle, :request, :exception]
        ],
        &__MODULE__.handle_event/4,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  test "attach/1 adds paddle telemetry steps to the request pipeline" do
    req = Paddle.Http.Telemetry.attach(Req.new())

    assert Keyword.has_key?(req.request_steps, :paddle_telemetry_start)
    assert Keyword.has_key?(req.response_steps, :paddle_telemetry_stop)
    assert Keyword.has_key?(req.error_steps, :paddle_telemetry_error)
  end

  test "executing a successful request emits start and stop telemetry events" do
    req =
      Req.new(
        method: :get,
        url: "/customers",
        adapter: fn request ->
          {request, Req.Response.new(status: 200, body: %{"ok" => true})}
        end
      )
      |> Paddle.Http.Telemetry.attach()

    assert {:ok, %Req.Response{status: 200}} = Req.request(req)

    assert_received {:telemetry_event, [:paddle, :request, :start], %{time: start_time},
                     %{request: %Req.Request{} = request}}

    assert is_integer(start_time)
    assert request.method == :get

    assert_received {:telemetry_event, [:paddle, :request, :stop], %{time: stop_time},
                     %{request: %Req.Request{}, response: %Req.Response{status: 200}}}

    assert is_integer(stop_time)
  end

  test "executing a failed request emits the exception telemetry event" do
    req =
      Req.new(
        method: :get,
        url: "/customers",
        retry: false,
        adapter: fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end
      )
      |> Paddle.Http.Telemetry.attach()

    assert {:error, %Req.TransportError{reason: :timeout}} = Req.request(req)

    assert_received {:telemetry_event, [:paddle, :request, :start], %{time: start_time},
                     %{request: %Req.Request{}}}

    assert is_integer(start_time)

    assert_received {:telemetry_event, [:paddle, :request, :exception], %{time: exception_time},
                     %{request: %Req.Request{}, exception: %Req.TransportError{reason: :timeout}}}

    assert is_integer(exception_time)
  end

  def handle_event(event, measurements, metadata, test_pid) do
    send(test_pid, {:telemetry_event, event, measurements, metadata})
  end
end
