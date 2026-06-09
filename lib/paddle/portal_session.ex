defmodule Paddle.PortalSession do
  @moduledoc """
  Represents a Paddle Customer Portal Session.

  Portal sessions allow developers to generate temporary authenticated
  session URLs for customers to manage their subscriptions and payment methods.

  The `urls` field is kept as a flat map to ensure forward compatibility
  with future portal URLs added by Paddle. It is redacted in inspections to
  avoid leaking short-lived authentication tokens in logs.
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
    # We construct a representation similar to what @derive {Inspect, except: ...} does
    # but explicitly adding urls: "[REDACTED]"
    
    fields =
      session
      |> Map.from_struct()
      |> Map.replace(:urls, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.PortalSession{", to_doc(fields, opts), "}"])
  end
end
