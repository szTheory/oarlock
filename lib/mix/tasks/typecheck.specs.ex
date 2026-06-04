defmodule Mix.Tasks.Typecheck.Specs do
  use Mix.Task

  @shortdoc "Fails when public defs in lib/paddle are missing @spec"
  @moduledoc """
  A project-local gate that enforces public-spec coverage across the intended
  Paddle SDK public seam.

  It mechanically scans all Elixir files in `lib/paddle/` and ensures that
  every public `def` in a non-sealed module has an immediately preceding `@spec`.
  Sealed internal modules (indicated by `@moduledoc false`) are explicitly excluded.
  """

  @impl Mix.Task
  @spec run(any()) :: no_return()
  def run(_args) do
    files =
      Path.wildcard("lib/paddle/**/*.ex") ++ Path.wildcard("lib/paddle.ex")

    failures =
      Enum.flat_map(files, fn file ->
        ast = file |> File.read!() |> Code.string_to_quoted!(columns: true)
        check_ast(ast, file)
      end)

    if failures == [] do
      Mix.shell().info("[:ok] typecheck.specs: All public seam functions have @spec.")
      System.halt(0)
    else
      Mix.shell().error("[:error] typecheck.specs: Missing @spec on public functions:")

      for {file, line, name, arity} <- failures do
        Mix.shell().error("  #{file}:#{line} - def #{name}/#{arity}")
      end

      System.halt(1)
    end
  end

  defp check_ast({:defmodule, _, [_aliases, [do: block]]}, file) do
    exprs =
      case block do
        {:__block__, _, block_exprs} -> block_exprs
        nil -> []
        expr -> [expr]
      end

    is_sealed =
      Enum.any?(exprs, fn
        {:@, _, [{:moduledoc, _, [false]}]} -> true
        _ -> false
      end)

    if is_sealed do
      []
    else
      check_exprs(exprs, file, nil, [], [])
    end
  end

  defp check_ast(_, _file), do: []

  defp check_exprs([], _file, _last_spec, _known_defs, acc), do: Enum.reverse(acc)

  defp check_exprs(
         [{:@, _, [{:spec, _, [{:"::", _, [signature, _]}]}]} | rest],
         file,
         _last_spec,
         known_defs,
         acc
       ) do
    case extract_name_arity(signature) do
      {name, arity} ->
        check_exprs(rest, file, {name, arity}, known_defs, acc)

      nil ->
        check_exprs(rest, file, nil, known_defs, acc)
    end
  end

  defp check_exprs([{:def, meta, [signature | _]} | rest], file, last_spec, known_defs, acc) do
    case extract_name_arity(signature) do
      {name, arity} ->
        # Multiple heads only need a spec on the first one or a general spec before them
        if Enum.member?(known_defs, {name, arity}) do
          check_exprs(rest, file, last_spec, known_defs, acc)
        else
          new_known = [{name, arity} | known_defs]

          if last_spec == {name, arity} do
            check_exprs(rest, file, nil, new_known, acc)
          else
            line = Keyword.get(meta, :line)
            check_exprs(rest, file, nil, new_known, [{file, line, name, arity} | acc])
          end
        end

      nil ->
        check_exprs(rest, file, nil, known_defs, acc)
    end
  end

  # Ignore doc tags, etc. between spec and def?
  defp check_exprs([{:@, _, [{doc_type, _, _}]} | rest], file, last_spec, known_defs, acc)
       when doc_type in [:doc, :impl] do
    # Pass the last_spec forward across @doc or @impl attributes.
    check_exprs(rest, file, last_spec, known_defs, acc)
  end

  defp check_exprs([_ | rest], file, _last_spec, known_defs, acc) do
    # Any other expression clears the last_spec
    check_exprs(rest, file, nil, known_defs, acc)
  end

  defp extract_name_arity({:when, _, [call | _]}) do
    extract_name_arity(call)
  end

  defp extract_name_arity({name, _, args}) when is_atom(name) do
    arity = if is_list(args), do: length(args), else: 0
    {name, arity}
  end

  defp extract_name_arity(_) do
    nil
  end
end
