defmodule Paddle.Subscription.ManagementUrls do
  @moduledoc """
  Represents management URLs for a Paddle Subscription.

  This is a data struct mapping the nested `management_urls` object from the API response.

  Both promoted fields are authenticated capabilities:
  - `update_payment_method`: A URL to hosted checkout where the customer can update their payment method.
  - `cancel`: A URL where the customer can cancel their subscription.

  Inspection exposes no value fields: `update_payment_method`, `cancel`, and the
  entire `raw_data` provider payload render as `[REDACTED]`. Inspection changes
  only the representation; stored runtime values remain unchanged and available
  to the caller.

  ## Related Paddle docs
  - [Subscription API reference](https://developer.paddle.com/api-reference/subscriptions/overview)
  """

  @typedoc """
  Subscription management URL capabilities.

  `Inspect` redacts `update_payment_method`, `cancel`, and the complete
  `raw_data` container. There are no visible value fields, and inspecting the
  struct does not modify its stored runtime data.
  """
  @type t :: %__MODULE__{
          update_payment_method: String.t() | nil,
          cancel: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:update_payment_method, :cancel, :raw_data]
end

defimpl Inspect, for: Paddle.Subscription.ManagementUrls do
  import Inspect.Algebra

  def inspect(management_urls, opts) do
    fields =
      management_urls
      |> Map.from_struct()
      |> Map.replace!(:update_payment_method, "[REDACTED]")
      |> Map.replace!(:cancel, "[REDACTED]")
      |> Map.replace!(:raw_data, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.Subscription.ManagementUrls{", to_doc(fields, opts), "}"])
  end
end
