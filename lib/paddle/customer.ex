defmodule Paddle.Customer do
  defstruct [
    :id,
    :name,
    :email,
    :marketing_consent,
    :status,
    :custom_data,
    :locale,
    :created_at,
    :updated_at,
    :import_meta,
    :raw_data
  ]
end
