defmodule Paddle.Subscription.ScheduledChange do
  @moduledoc """
  Represents a scheduled change for a Paddle Subscription.

  This is a data struct mapping the nested `scheduled_change` object from the API response.

  Contains fields:
  - `action`: The type of change scheduled (e.g., `cancel`, `pause`, `resume`).
  - `effective_at`: The ISO 8601 timestamp when the change will occur.
  - `resume_at`: The ISO 8601 timestamp when a paused subscription will automatically resume (if applicable).

  ## Related Paddle docs
  - [Pause a subscription](https://developer.paddle.com/concepts/subscriptions/pause-subscription)
  - [Cancel a subscription](https://developer.paddle.com/concepts/subscriptions/cancel-subscription)
  """

  @type t :: %__MODULE__{
          action: String.t() | nil,
          effective_at: String.t() | nil,
          resume_at: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:action, :effective_at, :resume_at, :raw_data]
end
