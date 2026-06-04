defmodule Paddle.Subscription.ManagementUrls do
  @moduledoc """
  Represents management URLs for a Paddle Subscription.
  
  Contains URLs that can be provided to customers to manage their subscription,
  such as updating their payment method or canceling the subscription.
  
  ## Related Paddle docs
  - [Subscription API reference](https://developer.paddle.com/api-reference/subscriptions/overview)
  """

  @type t :: %__MODULE__{
          update_payment_method: String.t() | nil,
          cancel: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:update_payment_method, :cancel, :raw_data]
end
