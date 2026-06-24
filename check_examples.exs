defmodule CheckExamples do
  def run do
    Code.compiler_options(ignore_module_conflict: true)
    
    # Need to load the app to get modules
    Mix.Task.run("loadpaths")
    {:ok, modules} = application_modules(:paddle)
    
    missing = []
    
    for mod <- modules do
      case Code.fetch_docs(mod) do
        {:docs_v1, _ann, _lang, format, _moduledoc, _meta, docs} when format in ["text/markdown", "none"] ->
          for {{kind, func_name, arity}, _anno, sig, doc_content, _meta} <- docs, kind == :function do
            case doc_content do
              %{"en" => text} ->
                unless String.contains?(text, "## Examples") or String.contains?(text, "## Example") do
                  IO.puts("Missing examples: #{inspect(mod)}.#{func_name}/#{arity}")
                end
              :none ->
                IO.puts("Missing @doc: #{inspect(mod)}.#{func_name}/#{arity}")
              :hidden ->
                # Hidden is fine, @doc false
                :ok
            end
          end
        _ -> :ok
      end
    end
  end
  
  defp application_modules(app) do
    Application.load(app)
    case Application.spec(app, :modules) do
      nil -> {:error, :not_found}
      modules -> {:ok, modules}
    end
  end
end

CheckExamples.run()
