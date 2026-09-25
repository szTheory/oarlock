defmodule TestRouter do
  use Plug.Router
  plug :match
  plug :dispatch
  
  get "/hello" do
    send_resp(conn, 200, "hello")
  end
  
  match _ do
    send_resp(conn, 404, "custom 404")
  end
end

{:ok, _pid} = Bandit.start_link(plug: TestRouter, port: 4445)
response = Req.get!("http://localhost:4445/unknown")
IO.inspect(response.body)
