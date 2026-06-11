defmodule Paddle.Subscription.ManagementUrls do
  @moduledoc """
  Represents management URLs for a Paddle Subscription.

  This is a data struct mapping the nested `management_urls` object from the API response.

  Contains fields:
  - `update_payment_method`: A URL to hosted checkout where the customer can update their payment method.
  - `cancel`: A URL where the customer can cancel their subscription.

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
