defmodule Paddle.Transaction do
  @moduledoc """
  Represents a Paddle Transaction.

  This is a data struct mapping the JSON response from the Paddle Billing API.

  A transaction entity represents an exchange of money for goods or services.
  It includes fields like:
  - `status`: The current state (e.g., draft, ready, billed, paid, completed).
  - `collection_mode`: Whether payment is collected automatically or manually via invoice.
  - `items`: The products or prices being purchased.
  - `checkout`: An object containing the hosted checkout URL for the transaction.
  - `details`: Breakdown of totals, taxes, and payouts.

  ## Related Paddle docs
  - [Transaction concept](https://developer.paddle.com/concepts/transactions)
  - [Transaction API reference](https://developer.paddle.com/api-reference/transactions/overview)
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          status: String.t() | nil,
          customer_id: String.t() | nil,
          address_id: String.t() | nil,
          business_id: String.t() | nil,
          custom_data: map() | nil,
          currency_code: String.t() | nil,
          origin: String.t() | nil,
          subscription_id: String.t() | nil,
          invoice_number: String.t() | nil,
          collection_mode: String.t() | nil,
          items: list(map()) | nil,
          details: map() | nil,
          payments: list(map()) | nil,
          checkout: Paddle.Transaction.Checkout.t() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          billed_at: String.t() | nil,
          revised_at: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :status,
    :customer_id,
    :address_id,
    :business_id,
    :custom_data,
    :currency_code,
    :origin,
    :subscription_id,
    :invoice_number,
    :collection_mode,
    :items,
    :details,
    :payments,
    :checkout,
    :created_at,
    :updated_at,
    :billed_at,
    :revised_at,
    :raw_data
  ]
end
