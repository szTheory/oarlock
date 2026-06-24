defmodule Paddle.Transaction.Checkout do
  @moduledoc """
  Represents Checkout details for a Paddle Transaction.

  This is a data struct mapping the nested `checkout` object from the API response.

  Contains fields:
  - `url`: The hosted checkout URL where a customer can pay for the transaction.

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
