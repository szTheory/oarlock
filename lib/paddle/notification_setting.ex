defmodule Paddle.NotificationSetting do
  @moduledoc """
  Represents a Paddle Notification Setting.

  Notification settings control where and how webhooks are delivered.

  **Note:** The `endpoint_secret_key` field is only returned immediately upon 
  creation of a new notification setting and will be `nil` in all subsequent 
  retrieval requests (such as `get/2`, `list/2`, etc). You must store this 
  secret securely when it is first provisioned.

  The `raw_data` field contains the original, unparsed response from the Paddle API.
  """

  @type t :: %__MODULE__{
          id: String.t() | nil,
          description: String.t() | nil,
          type: String.t() | nil,
          destination: String.t() | nil,
          active: boolean() | nil,
          api_version: integer() | nil,
          include_sensitive_fields: boolean() | nil,
          subscribed_events: list(map()) | nil,
          endpoint_secret_key: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :description,
    :type,
    :destination,
    :active,
    :api_version,
    :include_sensitive_fields,
    :subscribed_events,
    :endpoint_secret_key,
    :raw_data
  ]
end
