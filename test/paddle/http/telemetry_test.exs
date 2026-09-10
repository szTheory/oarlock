defmodule Paddle.Http.TelemetryTest do
  use ExUnit.Case, async: true

  @events [
    [:paddle, :request, :start],
    [:paddle, :request, :stop],
    [:paddle, :request, :exception]
  ]

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

  setup do
    handler_id = {__MODULE__, make_ref()}

    :ok = :telemetry.attach_many(handler_id, @events, &__MODULE__.handle_event/4, self())
    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  test "attach/1 places terminal telemetry before retry" do
    req = Paddle.Http.Telemetry.attach(Req.new())

    assert Keyword.has_key?(req.request_steps, :paddle_telemetry_start)

    assert step_index(req.response_steps, :paddle_telemetry_stop) <
             step_index(req.response_steps, :retry)

    assert step_index(req.error_steps, :paddle_telemetry_error) <
             step_index(req.error_steps, :retry)
  end

  test "a successful physical attempt emits exact allowlisted start and stop payloads" do
    req =
      request(fn request ->
        {request, Req.Response.new(status: 200, body: %{"ok" => true})}
      end)

    assert {:ok, %Req.Response{status: 200}} = Req.request(req)

    assert [
             {[:paddle, :request, :start], start_measurements, start_metadata},
             {[:paddle, :request, :stop], stop_measurements, stop_metadata}
           ] = collect_events(2)

    assert exact_keys(start_measurements) == [:system_time]
    assert exact_keys(start_metadata) == [:attempt, :host, :method, :operation, :route]
    assert is_integer(start_measurements.system_time)

    assert start_metadata == %{
             attempt: 1,
             host: "sandbox-api.paddle.com",
             method: :get,
             operation: :list_customers,
             route: "/customers"
           }

    assert exact_keys(stop_measurements) == [:duration]

    assert stop_metadata == %{
             attempt: 1,
             host: "sandbox-api.paddle.com",
             method: :get,
             operation: :list_customers,
             result: :ok,
             route: "/customers",
             status: 200
           }

    assert is_integer(stop_measurements.duration)
    assert stop_measurements.duration >= 0
  end

  test "provider and transport failures use exact terminal payloads" do
    provider_req =
      request(fn request ->
        {request, Req.Response.new(status: 422, body: %{"error" => "provider-canary"})}
      end)

    assert {:ok, %Req.Response{status: 422}} = Req.request(provider_req)

    assert [
             {[:paddle, :request, :start], %{system_time: _}, start_metadata},
             {[:paddle, :request, :stop], provider_measurements, provider_metadata}
           ] = collect_events(2)

    assert exact_keys(start_metadata) == [:attempt, :host, :method, :operation, :route]
    assert exact_keys(provider_measurements) == [:duration]

    assert provider_metadata == %{
             attempt: 1,
             host: "sandbox-api.paddle.com",
             method: :get,
             operation: :list_customers,
             result: :error,
             route: "/customers",
             status: 422
           }

    transport_req =
      request(fn request -> {request, %Req.TransportError{reason: :timeout}} end, retry: false)

    assert {:error, %Req.TransportError{reason: :timeout}} = Req.request(transport_req)

    assert [
             {[:paddle, :request, :start], %{system_time: _}, _start_metadata},
             {[:paddle, :request, :exception], exception_measurements, exception_metadata}
           ] = collect_events(2)

    assert exact_keys(exception_measurements) == [:duration]

    assert exception_metadata == %{
             attempt: 1,
             error_class: :transport_error,
             host: "sandbox-api.paddle.com",
             method: :get,
             operation: :list_customers,
             result: :error,
             route: "/customers"
           }
  end

  test "two-attempt success and four-attempt terminal reads emit one ordered pair per attempt" do
    {:ok, success_counter} = Agent.start_link(fn -> 0 end)

    success_req =
      request(fn request ->
        attempt = Agent.get_and_update(success_counter, fn count -> {count + 1, count + 1} end)
        status = if attempt == 1, do: 503, else: 200
        {request, Req.Response.new(status: status, body: %{})}
      end)

    assert {:ok, %Req.Response{status: 200}} = Req.request(success_req)
    assert_attempt_pairs(collect_events(4), [503, 200])

    terminal_req =
      request(fn request ->
        {request, Req.Response.new(status: 503, body: %{})}
      end)

    assert {:ok, %Req.Response{status: 503}} = Req.request(terminal_req)
    assert_attempt_pairs(collect_events(8), [503, 503, 503, 503])
  end

  def handle_event(event, measurements, metadata, test_pid) do
    if self() == test_pid do
      send(test_pid, {:telemetry_event, event, measurements, metadata})
    end
  end

  defp request(adapter, opts \\ []) do
    Req.new(
      base_url: "https://sandbox-api.paddle.com",
      method: :get,
      url: "/customers",
      retry_delay: fn _retry_count -> 0 end,
      adapter: Adapter
    )
    |> Req.Request.merge_options(opts)
    |> Req.Request.put_private(:paddle_test_adapter, adapter)
    |> Req.Request.put_private(:paddle_request_context, %{
      method: :get,
      operation: :list_customers,
      route: "/customers"
    })
    |> Paddle.Http.Telemetry.attach()
  end

  defp step_index(steps, name), do: Enum.find_index(steps, &(elem(&1, 0) == name))

  defp collect_events(count) do
    for _ <- 1..count do
      assert_receive {:telemetry_event, event, measurements, metadata}
      {event, measurements, metadata}
    end
  end

  defp assert_attempt_pairs(events, statuses) do
    assert Enum.map(events, fn {event, _measurements, metadata} ->
             {List.last(event), metadata.attempt}
           end) ==
             Enum.flat_map(1..length(statuses), fn attempt ->
               [{:start, attempt}, {:stop, attempt}]
             end)

    assert Enum.map(Enum.take_every(Enum.drop(events, 1), 2), fn
             {[:paddle, :request, :stop], %{duration: duration}, metadata} ->
               assert duration >= 0
               {metadata.status, metadata.result}
           end) == Enum.map(statuses, &{&1, if(&1 in 200..299, do: :ok, else: :error)})
  end

  defp exact_keys(map), do: map |> Map.keys() |> Enum.sort()
end
