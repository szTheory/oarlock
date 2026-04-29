defmodule Paddle.Subscription.ScheduledChange do
  defstruct [:action, :effective_at, :resume_at, :raw_data]
end
