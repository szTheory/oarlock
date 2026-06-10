defmodule Paddle.Price do
  @moduledoc """
  Represents a Paddle Price.

  Prices are used to bill customers for products or subscriptions.
  This struct encapsulates their details, such as `unit_price`, `billing_cycle`, and `tax_mode`.

  The `raw_data` field contains the original, unparsed response from the Paddle API.

  > **Important Note:** Custom prices created dynamically during checkout are NOT returned by this Catalog API. This API only returns predefined Catalog prices.

  ## Related Paddle docs
  - [Price entity](https://developer.paddle.com/api-reference/prices/overview)
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          product_id: String.t() | nil,
          description: String.t() | nil,
          type: String.t() | nil,
          name: String.t() | nil,
          billing_cycle: map() | nil,
          trial_period: map() | nil,
          tax_mode: String.t() | nil,
          unit_price: map() | nil,
          unit_price_overrides: list(map()) | nil,
          quantity: map() | nil,
          status: String.t() | nil,
          custom_data: map() | nil,
          import_meta: map() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :product_id,
    :description,
    :type,
    :name,
    :billing_cycle,
    :trial_period,
    :tax_mode,
    :unit_price,
    :unit_price_overrides,
    :quantity,
    :status,
    :custom_data,
    :import_meta,
    :created_at,
    :updated_at,
    :raw_data
  ]
end
