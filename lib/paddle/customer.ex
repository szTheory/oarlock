defmodule Paddle.Customer do
  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          email: String.t() | nil,
          marketing_consent: boolean() | nil,
          status: String.t() | nil,
          custom_data: map() | nil,
          locale: String.t() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil,
          import_meta: map() | nil,
          raw_data: map() | nil
        }

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
