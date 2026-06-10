defmodule Paddle.Subscription.ScheduledChange do
  @moduledoc """
  Represents a scheduled change for a Paddle Subscription.

  Contains details about actions scheduled to take effect on a subscription
  at a future date (e.g., pause, cancel, or resume).

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
