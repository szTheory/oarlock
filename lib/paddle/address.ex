defmodule Paddle.Address do
  @moduledoc """
  Represents a Customer's Address in Paddle.

  Addresses are used for tax calculation, compliance, and invoicing. They are
  always associated with a specific `customer_id`. The struct holds localization
  information like `country_code`, `postal_code`, and `region`.

  The `raw_data` field contains the original, unparsed response from the Paddle API.

  ## Related Paddle docs
  - [Address entity](https://developer.paddle.com/api-reference/addresses/overview)
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          customer_id: String.t() | nil,
          description: String.t() | nil,
          first_line: String.t() | nil,
          second_line: String.t() | nil,
          city: String.t() | nil,
          postal_code: String.t() | nil,
          region: String.t() | nil,
          country_code: String.t() | nil,
          custom_data: map() | nil,
          status: String.t() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          import_meta: map() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :customer_id,
    :description,
    :first_line,
    :second_line,
    :city,
    :postal_code,
    :region,
    :country_code,
    :custom_data,
    :status,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
