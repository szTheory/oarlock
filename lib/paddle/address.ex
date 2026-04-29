defmodule Paddle.Address do
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
