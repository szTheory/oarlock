defmodule Paddle.NotificationSetting do
  @moduledoc """
  Represents a Paddle Notification Setting.

  Notification settings control where and how webhooks are delivered.

  **Note:** The `endpoint_secret_key` field is only returned immediately upon 
  creation of a new notification setting and will be `nil` in all subsequent 
  retrieval requests (such as `get/2`, `list/2`, etc). You must store this 
  secret securely when it is first provisioned.

  Inspection keeps `id`, `description`, `type`, `active`, `api_version`,
  `include_sensitive_fields`, and `subscribed_events` visible. It redacts
  `destination`, `endpoint_secret_key`, and the entire `raw_data` provider
  payload with `[REDACTED]`. Inspection changes only the rendered representation;
  the stored runtime values remain unchanged and available to the caller.
  """

  @typedoc """
  A notification setting.

  `Inspect` exposes the ordinary `id`, `description`, `type`, `active`,
  `api_version`, `include_sensitive_fields`, and `subscribed_events` fields. It
  redacts the capability-bearing `destination` and `endpoint_secret_key` fields
  plus the complete `raw_data` container without modifying stored runtime data.
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

defimpl Inspect, for: Paddle.NotificationSetting do
  import Inspect.Algebra

  def inspect(setting, opts) do
    fields =
      setting
      |> Map.from_struct()
      |> Map.replace!(:destination, "[REDACTED]")
      |> Map.replace!(:endpoint_secret_key, "[REDACTED]")
      |> Map.replace!(:raw_data, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.NotificationSetting{", to_doc(fields, opts), "}"])
  end
end
