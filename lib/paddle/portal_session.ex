defmodule Paddle.PortalSession do
  @moduledoc """
  Represents a Paddle Customer Portal Session.

  Portal sessions allow developers to generate temporary authenticated
  session URLs for customers to manage their subscriptions and payment methods.

  The `urls` field is kept as a flat map to ensure forward compatibility with
  future portal URLs added by Paddle. Inspection keeps `id`, `customer_id`,
  `created_at`, and `custom_data` visible while redacting both `urls` and the
  entire `raw_data` provider payload with `[REDACTED]`. Inspection changes only
  the rendered representation; stored runtime values remain unchanged.
  """

  @typedoc """
  A customer portal session.

  `Inspect` exposes the ordinary `id`, `customer_id`, `created_at`, and
  `custom_data` fields. It redacts the capability-bearing `urls` field and the
  complete `raw_data` container without modifying stored runtime data.
  """
  @type t :: %__MODULE__{
          id: String.t() | nil,
          customer_id: String.t() | nil,
          urls: map() | nil,
          created_at: String.t() | nil,
          custom_data: map() | nil,
          raw_data: map() | nil
        }

  defstruct [
    :id,
    :customer_id,
    :urls,
    :created_at,
    :custom_data,
    :raw_data
  ]
end

defimpl Inspect, for: Paddle.PortalSession do
  import Inspect.Algebra

  def inspect(session, opts) do
    fields =
      session
      |> Map.from_struct()
      |> Map.replace!(:urls, "[REDACTED]")
      |> Map.replace!(:raw_data, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.PortalSession{", to_doc(fields, opts), "}"])
  end
end
