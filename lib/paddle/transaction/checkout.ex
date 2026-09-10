defmodule Paddle.Transaction.Checkout do
  @moduledoc """
  Represents Checkout details for a Paddle Transaction.

  This is a data struct mapping the nested `checkout` object from the API response.

  The `url` field is an authenticated hosted-checkout capability where a customer
  can pay for the transaction. Inspection exposes no value fields: `url` and the
  entire `raw_data` provider payload render as `[REDACTED]`. Inspection changes
  only the representation; stored runtime values remain unchanged and available
  to the caller.

  ## Related Paddle docs
  - [Hosted checkout concept](https://developer.paddle.com/concepts/transactions/checkout)
  - [Transaction API reference](https://developer.paddle.com/api-reference/transactions/overview)
  """

  @typedoc """
  Hosted checkout capability details.

  `Inspect` redacts `url` and the complete `raw_data` container. There are no
  visible value fields, and inspecting the struct does not modify its stored
  runtime data.
  """
  @type t :: %__MODULE__{
          url: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:url, :raw_data]
end

defimpl Inspect, for: Paddle.Transaction.Checkout do
  import Inspect.Algebra

  def inspect(checkout, opts) do
    fields =
      checkout
      |> Map.from_struct()
      |> Map.replace!(:url, "[REDACTED]")
      |> Map.replace!(:raw_data, "[REDACTED]")
      |> Enum.sort()

    concat(["%Paddle.Transaction.Checkout{", to_doc(fields, opts), "}"])
  end
end
