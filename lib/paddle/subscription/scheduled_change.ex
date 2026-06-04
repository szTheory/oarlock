defmodule Paddle.Subscription.ScheduledChange do
  @type t :: %__MODULE__{
          action: String.t() | nil,
          effective_at: String.t() | nil,
          resume_at: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:action, :effective_at, :resume_at, :raw_data]
end
