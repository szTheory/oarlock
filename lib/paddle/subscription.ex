defmodule Paddle.Subscription do
  defstruct [
    :id,
    :status,
    :customer_id,
    :address_id,
    :business_id,
    :currency_code,
    :collection_mode,
    :custom_data,
    :items,
    :scheduled_change,
    :management_urls,
    :current_billing_period,
    :billing_cycle,
    :billing_details,
    :discount,
    :next_billed_at,
    :started_at,
    :first_billed_at,
    :paused_at,
    :canceled_at,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
