defmodule Paddle.Webhooks do
  @required_keys ~w(event_id event_type occurred_at notification_id data)

  def parse_event(raw_body) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, %{"data" => data} = payload} when is_map(data) ->
        if valid_payload?(payload) do
          {:ok, Paddle.Http.build_struct(Paddle.Event, payload)}
        else
          {:error, :invalid_event_payload}
        end

      {:ok, _payload} ->
        {:error, :invalid_event_payload}

      {:error, _reason} ->
        {:error, :invalid_json}
    end
  end

  defp valid_payload?(payload) do
    Enum.all?(@required_keys, &Map.has_key?(payload, &1))
  end
end
