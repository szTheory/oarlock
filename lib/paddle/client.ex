defmodule Paddle.Client do
  @type t :: %__MODULE__{
          api_key: String.t(),
          environment: :sandbox | :live,
          req: struct()
        }

  @enforce_keys [:api_key, :environment]
  defstruct [:api_key, :environment, :req]

  @spec new!(keyword()) :: t()
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
        headers: [{"Paddle-Version", "1"}],
        retry: :transient,
        max_retries: 3
      )
      |> Paddle.Http.Telemetry.attach()

    %__MODULE__{api_key: api_key, environment: environment, req: req}
  end
end
