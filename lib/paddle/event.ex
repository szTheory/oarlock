defmodule Paddle.Event do
  @moduledoc """
  Represents an event triggered by Paddle, usually delivered via Webhooks.

  When a Paddle webhook is received and verified, the payload is parsed into this
  struct. The `data` field contains the resource (e.g. `%Paddle.Transaction{}`)
  that the event is about, while `raw_data` retains the original unparsed map.
  """

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
