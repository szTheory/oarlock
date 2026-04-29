defmodule Paddle.Transaction do
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
