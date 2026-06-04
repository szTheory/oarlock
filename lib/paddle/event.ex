defmodule Paddle.Event do
  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          event_type: String.t() | nil,
          occurred_at: String.t() | nil,
          notification_id: String.t() | nil,
          data: map() | nil,
          raw_data: map() | nil
        }

  defstruct [:event_id, :event_type, :occurred_at, :notification_id, :data, :raw_data]
end
