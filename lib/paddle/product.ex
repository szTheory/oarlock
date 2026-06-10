defmodule Paddle.Product do
  @moduledoc """
  Represents a Paddle Product.

  Products are the primary items in the Paddle Catalog. This struct encapsulates
  their details, such as `name`, `status`, and `tax_category`.

  > #### Warning {: .warning}
  > Custom products created dynamically during checkout are NOT returned by this Catalog API.
  > This API only returns standard Catalog products.

  The `raw_data` field contains the original, unparsed response from the Paddle API.

  ## Related Paddle docs
  - [Product entity](https://developer.paddle.com/api-reference/products/overview)
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          status: String.t() | nil,
          tax_category: String.t() | nil,
          description: String.t() | nil,
          image_url: String.t() | nil,
          custom_data: map() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          import_meta: map() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :name,
    :status,
    :tax_category,
    :description,
    :image_url,
    :custom_data,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
