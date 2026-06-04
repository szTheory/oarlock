defmodule Paddle.Transaction do
  @moduledoc """
  Represents a Paddle Transaction.
  
  A transaction entity represents an exchange of money for goods or services.
  It is generated for one-time purchases and as part of a recurring subscription lifecycle.
  
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
