defmodule Paddle.Phase32ProofFormatter do
  @moduledoc false
  use GenServer

  def init(_opts) do
    path = Application.fetch_env!(:oarlock, :phase32_proof_events_file)
    {:ok, path}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _reason}}}, path),
    do: {:noreply, path}

  def handle_cast({:test_finished, %ExUnit.Test{module: module, name: name, tags: tags}}, path) do
    case tags[:phase32_proof_id] do
      nil -> :ok
      proof_id -> File.write!(path, "#{proof_id}|#{inspect(module)}|#{name}\n", [:append])
    end

    {:noreply, path}
  end

  def handle_cast(_event, path), do: {:noreply, path}
  def handle_info(_event, path), do: {:noreply, path}
end
