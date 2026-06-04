defmodule Paddle.Page do
  @type t :: %__MODULE__{
          data: list(map() | struct()),
          meta: map()
        }

  defstruct [:data, :meta]

  def next_cursor(%__MODULE__{meta: %{"pagination" => %{"next" => next}}}) when is_binary(next) do
    next
  end

  def next_cursor(_), do: nil
end
