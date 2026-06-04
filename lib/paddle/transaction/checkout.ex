defmodule Paddle.Transaction.Checkout do
  @type t :: %__MODULE__{
          url: String.t() | nil,
          raw_data: map() | nil
        }

  defstruct [:url, :raw_data]
end
