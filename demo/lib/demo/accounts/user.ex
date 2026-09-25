defmodule Demo.Accounts.User do
  @moduledoc """
  A simple, in-memory struct representing our mock user.
  We use this to satisfy UI elements requiring an authenticated user.
  """
  defstruct [:id, :name, :email]
end
