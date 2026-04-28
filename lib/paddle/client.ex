defmodule Paddle.Client do
  @enforce_keys [:api_key, :environment]
  defstruct [:api_key, :environment, :req]

  def new!(opts \\ []) do
    api_key = Keyword.fetch!(opts, :api_key)
    environment = Keyword.get(opts, :environment, :sandbox)

    base_url =
      if environment == :live,
        do: "https://api.paddle.com",
        else: "https://sandbox-api.paddle.com"

    req =
      Req.new(
        base_url: base_url,
        auth: {:bearer, api_key},
        headers: [{"Paddle-Version", "1"}]
      )
      |> Paddle.Http.Telemetry.attach()

    %__MODULE__{api_key: api_key, environment: environment, req: req}
  end
end
