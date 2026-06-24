defmodule DocChecker do
  def run do
    modules =
      :code.all_loaded()
      |> Enum.map(&elem(&1, 0))
      |> Enum.filter(fn m -> String.starts_with?(to_string(m), "Elixir.Paddle") end)

    Enum.each(modules, fn mod ->
      case Code.fetch_docs(mod) do
        {:docs_v1, _, _, _, :hidden, _, _} ->
          :ok
        {:docs_v1, _, _, _, _, _, docs} ->
          Enum.each(docs, fn
            {{:function, name, arity}, _, _, doc_content, _} ->
              if doc_content == :none do
                IO.puts("FAIL: #{mod}.#{name}/#{arity} missing @doc")
              else
                # Check for examples
                case doc_content do
                  %{"en" => doc_str} ->
                    unless String.contains?(doc_str, "## Examples") || String.contains?(doc_str, "## Example") do
                      IO.puts("FAIL: #{mod}.#{name}/#{arity} missing ## Examples in @doc")
                    end
                  _ ->
                    IO.puts("FAIL: #{mod}.#{name}/#{arity} has unexpected doc format")
                end
              end
            _ -> :ok
          end)
        _ ->
          IO.puts("FAIL: Could not fetch docs for #{mod}")
      end
    end)
  end
end
DocChecker.run()
