defmodule Paddle.Adjustment do
  @moduledoc """
  Represents a Paddle Adjustment.

  An adjustment represents a refund or credit for a transaction.
  This struct encapsulates details such as `action`, `reason`, and the `transaction_id`.

  The `raw_data` field contains the original, unparsed response from the Paddle API.

  ## Related Paddle docs
  - [Adjustments API reference](https://developer.paddle.com/api-reference/adjustments/overview)
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          action: String.t() | nil,
          transaction_id: String.t() | nil,
          subscription_id: String.t() | nil,
          customer_id: String.t() | nil,
          reason: String.t() | nil,
          credit_applied_to_balance: boolean() | nil,
          currency_code: String.t() | nil,
          status: String.t() | nil,
          items: list(map()) | nil,
          totals: map() | nil,
          payouts: map() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :action,
    :transaction_id,
    :subscription_id,
    :customer_id,
    :reason,
    :credit_applied_to_balance,
    :currency_code,
    :status,
    :items,
    :totals,
    :payouts,
    :created_at,
    :updated_at,
    :raw_data
  ]
end
