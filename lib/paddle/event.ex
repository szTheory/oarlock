defmodule Paddle.Event do
  defstruct [:event_id, :event_type, :occurred_at, :notification_id, :data, :raw_data]
end
