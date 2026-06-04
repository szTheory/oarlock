defmodule Paddle.Subscription do
  @moduledoc """
  Represents a Paddle Subscription.
  
  A subscription entity tracks the recurring billing relationship with a customer,
  including items, billing periods, scheduled changes, and management URLs.
  
  ## Related Paddle docs
  - [Subscription concept](https://developer.paddle.com/concepts/subscriptions)
  - [Subscription API reference](https://developer.paddle.com/api-reference/subscriptions/overview)
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          status: String.t() | nil,
          customer_id: String.t() | nil,
          address_id: String.t() | nil,
          business_id: String.t() | nil,
          currency_code: String.t() | nil,
          collection_mode: String.t() | nil,
          custom_data: map() | nil,
          items: list(map()) | nil,
          scheduled_change: Paddle.Subscription.ScheduledChange.t() | nil,
          management_urls: Paddle.Subscription.ManagementUrls.t() | nil,
          current_billing_period: map() | nil,
          billing_cycle: map() | nil,
          billing_details: map() | nil,
          discount: map() | nil,
          next_billed_at: String.t() | nil,
          started_at: String.t() | nil,
          first_billed_at: String.t() | nil,
          paused_at: String.t() | nil,
          canceled_at: String.t() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          import_meta: map() | nil,
          raw_data: map() | nil
        }

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
