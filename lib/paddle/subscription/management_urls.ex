defmodule Paddle.Subscription.ManagementUrls do
  @type t :: %__MODULE__{
          update_payment_method: String.t() | nil,
          cancel: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:update_payment_method, :cancel, :raw_data]
end
