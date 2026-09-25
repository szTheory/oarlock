# Start the Paddle MockServer on a random port for tests
{:ok, _pid} = Paddle.MockServer.start_link(port: 4448)
Application.put_env(:demo, :paddle_base_url, "http://localhost:4448")

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Demo.Repo, :manual)
