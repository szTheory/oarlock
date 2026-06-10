defmodule Paddle.Transaction.Checkout do
  @moduledoc """
  Represents Checkout details for a Paddle Transaction.

  Contains the hosted checkout URL where a customer can pay for the transaction.

  ## Related Paddle docs
  - [Hosted checkout concept](https://developer.paddle.com/concepts/transactions/checkout)
  - [Transaction API reference](https://developer.paddle.com/api-reference/transactions/overview)
  """

  @type t :: %__MODULE__{
          url: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:url, :raw_data]
end
